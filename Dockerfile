FROM python:3.14-slim

LABEL NAME=infrastructure
LABEL VERSION=1.0.0

ARG TOFU_VERSION=1.12.5
ARG TFLINT_VERSION=0.64.0
ARG TARGETARCH

WORKDIR /app/

# Dependencies for pre-commit and its hooks.
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git libatomic1 shellcheck unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install OpenTofu.
RUN curl -fsSL "https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/tofu_${TOFU_VERSION}_linux_${TARGETARCH}.tar.gz" -o /tmp/tofu.tar.gz \
    && tar -xzf /tmp/tofu.tar.gz -C /usr/local/bin tofu \
    && rm /tmp/tofu.tar.gz

# Install TFLint.
RUN curl -fsSL "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_${TARGETARCH}.zip" -o /tmp/tflint.zip \
    && unzip /tmp/tflint.zip tflint -d /usr/local/bin \
    && rm /tmp/tflint.zip

# Point the pre-commit-terraform hooks at OpenTofu.
ENV PCT_TFPATH=tofu

# Install pre-commit.
RUN pip install --no-cache-dir pre-commit

# Install pre-commit hooks.
COPY .pre-commit-config.yaml .pre-commit-config.yaml
RUN git init . && pre-commit install-hooks
RUN git config --global --add safe.directory /app

ENTRYPOINT [ "bash" ]
