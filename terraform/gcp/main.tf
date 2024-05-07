terraform {
  required_version = ">= 1.8"

  required_providers {
    google = ">= 5.8.0"
  }

  backend "gcs" {}
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "gcs_sign_url_service_account" {
  account_id   = var.name
  display_name = "Service account to create signed URLs for Google Cloud Storage."
}

resource "google_project_iam_binding" "storage_role_for_gcs_sign_url_service_account" {
  project = var.project_id
  role    = "roles/storage.editor"
  members = [
    "serviceAccount:${google_service_account.gcs_sign_url_service_account.email}",
  ]
}

resource "google_service_account_key" "gcs_sign_url_key" {
  service_account_id = google_service_account.gcs_sign_url_service_account.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "local_file" "service_account_key_file" {
  content  = base64decode(google_service_account_key.gcs_sign_url_key.private_key)
  filename = "${path.module}/../.secrets/application_default_credentials.json"
}

resource "google_project_iam_binding" "storage_role_for_compute_engine_default_service_account" {
  project = var.project_id
  role    = "roles/storage.editor"
  members = [
    "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com ",
  ]
}

resource "google_project_iam_binding" "cloudsql_role_for_compute_engine_default_service_account" {
  project = var.project_id
  role    = "roles/cloudsql.editor"
  members = [
    "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com ",
  ]
}


resource "google_sql_database_instance" "db" {
  name             = "${var.name}-db"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier    = "db-perf-optimized-N-2"
    edition = "ENTERPRISE_PLUS"
  }
}

resource "google_sql_user" "db" {
  instance = google_sql_database_instance.db.name
  name     = var.db_user
  password = var.db_password
}

resource "google_sql_database" "db" {
  name     = "${var.name}-db"
  instance = google_sql_database_instance.db.name
}

resource "google_project_service" "run_api" {
  project            = var.project_id
  service            = "run.googleapis.com"
  disable_on_destroy = true
}

resource "google_artifact_registry_repository" "artifact_repository" {
  location      = var.location
  repository_id = var.name
  format        = "DOCKER"
}

resource "null_resource" "docker_build_api" {
  provisioner "local-exec" {
    command = "docker build --file ../Dockerfile --target base --tag api --cache-from=api-bare --cache-from=api --build-arg BUILDKIT_INLINE_CACHE=1 --platform linux/amd64 ${path.module}"
  }

  triggers = {
    always_run = "${timestamp()}"
  }

  depends_on = [local_file.service_account_key_file]
}

resource "null_resource" "docker_tag_api" {
  provisioner "local-exec" {
    command = "docker tag api ${var.image_name}:${var.api_hash}"
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}

resource "null_resource" "docker_push_api" {
  provisioner "local-exec" {
    command = "docker push ${var.image_name}:${var.api_hash}"
  }

  triggers = {
    always_run = "${timestamp()}"
  }

  depends_on = [google_artifact_registry_repository.artifact_repository, null_resource.docker_tag_api]
}

resource "google_cloud_run_v2_service" "run_service" {
  project  = var.project_id
  name     = var.name
  location = var.location
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = format("%s:%s", var.image_name, var.api_hash)
      resources {
        limits = {
          cpu    = "2.0"
          memory = "8000Mi"
        }
      }
      ports {
        container_port = 80
      }
      env {
        name  = "ENVIRONMENT"
        value = "PRODUCTION"
      }
      env {
        name  = "DB_DIALECT"
        value = "postgresql+pg8000"
      }
      env {
        name  = "DB_NAME"
        value = "${var.name}-db"
      }
      env {
        name  = "DB_USER"
        value = var.db_user
      }
      env {
        name  = "DB_PASSWORD"
        value = var.db_password
      }
      env {
        name  = "GOOGLE_APPLICATION_CREDENTIALS"
        value = var.gcp_credentials_path
      }
      env {
        name  = "GCS_BUCKET_NAME"
        value = var.name
      }
      env {
        name  = "INSTANCE_UNIX_SOCKET"
        value = "/cloudsql/${google_sql_database_instance.db.connection_name}/.s.PGSQL.5432"
      }
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
      liveness_probe {
        failure_threshold     = 3
        initial_delay_seconds = 120
        timeout_seconds       = 5
        period_seconds        = 60

        http_get {
          path = "/api"
        }
      }
    }
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.db.connection_name]
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  depends_on = [google_project_service.run_api, null_resource.docker_push_api, google_sql_database_instance.db]
}

# Allow unauthenticated users to invoke the service.
# NOTE: Auth will be handled inside the application using basic auth.
resource "google_cloud_run_service_iam_member" "run_all_users" {
  service  = google_cloud_run_v2_service.run_service.name
  location = google_cloud_run_v2_service.run_service.location
  role     = "roles/run.invoker"
  member   = "allUsers"

  depends_on = [google_cloud_run_v2_service.run_service]
}

output "service_url" {
  value = google_cloud_run_v2_service.run_service.uri
}

resource "google_storage_bucket" "create_bucket" {
  name          = var.name
  location      = var.location
  force_destroy = true

  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
}
