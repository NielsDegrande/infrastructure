FROM python:3.13

LABEL NAME=infrastructure
LABEL VERSION=1.0.0

WORKDIR /app/

# Dependencies for pre-commit.
RUN apt-get update \
    && apt-get install git build-essential shellcheck -y \
    && apt-get clean
RUN pip install --no-cache-dir pre-commit
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && . ~/.cargo/env
ENV PATH="/root/.cargo/bin:$PATH"

# Install pre-commit hooks.
COPY .pre-commit-config.yaml .pre-commit-config.yaml
RUN git init . && pre-commit install-hooks
RUN git config --global --add safe.directory /app

ENTRYPOINT [ "bash" ]
