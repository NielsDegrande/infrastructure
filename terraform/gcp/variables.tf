variable "project_id" {
  type    = string
}

variable "project_number" {
  type    = string
}

variable "region" {
  type    = string
}

variable "location" {
  type    = string
}

variable "name" {
  type    = string
  default = "template"
}

variable "image_name" {
  type    = string
}

variable "api_hash" {
  type = string
}

variable "gcp_credentials_path" {
  type    = string
}

variable "db_user" {
  type    = string
  default = "postgres"
}

variable "db_password" {
  type = string
}
