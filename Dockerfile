FROM python:3.13

LABEL NAME=infrastructure
LABEL VERSION=1.0.0

WORKDIR /app/

# Dependencies for pre-commit and Terraform.
RUN apt-get update \
    && apt-get install -y git build-essential shellcheck gnupg software-properties-common curl

# Install Terraform.
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null \
    && gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update \
    && apt-get install -y terraform \
    && apt-get clean

# Install pre-commit.
RUN pip install --no-cache-dir pre-commit

# Install Rust (required for pre-commit).
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && . ~/.cargo/env
ENV PATH="/root/.cargo/bin:$PATH"

# Install pre-commit hooks.
COPY .pre-commit-config.yaml .pre-commit-config.yaml
RUN git init . && pre-commit install-hooks
RUN git config --global --add safe.directory /app

ENTRYPOINT [ "bash" ]
