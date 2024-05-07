FROM python:3.11

LABEL NAME=infra
LABEL VERSION=1.0.0

WORKDIR /app/

# Dependencies for pre-commit.
RUN apt-get update \
    && apt-get install git build-essential shellcheck -y \
    && apt-get clean
RUN pip install pre-commit
COPY .pre-commit-config.yaml .pre-commit-config.yaml

# Install pre-commit hooks.
RUN git init . && pre-commit install-hooks
RUN git config --global --add safe.directory /app

ENTRYPOINT [ "bash" ]
