#!/usr/bin/make

## help: Print help.
.PHONY: help
help:
	@echo Possible commands:
	@cat Makefile | grep '##' | grep -v "Makefile" | sed -e 's/^##/  -/'

## install_dev: Install dependencies for development.
.PHONY: install_dev
install_dev:
	pip install pre-commit
	pre-commit install

## build_test: Build the test image.
.PHONY: build_test
build_test:
	docker build \
		--file Dockerfile \
		--tag infra-test  \
		--cache-from=infra-test \
		--build-arg BUILDKIT_INLINE_CACHE=1 \
		${PWD}

## run_pre_commit: Run pre-commit.
.PHONY: run_pre_commit
run_pre_commit: build_test
	docker run --rm \
		--volume ${PWD}:/app \
		infra-test \
		-c "pre-commit run --all-files"
