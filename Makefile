SHELL := /bin/bash

# makefile location
ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
# fython src folder
SRC_DIR:="$(ROOT_DIR)/src"

BOOTSTRAP_DOCKER_TAG:="fython:bootstrap"
COMPILER_DOCKER_TAG:="fython:compiler"
SHELL_DOCKER_TAG:="fython:shell"
TESTS_DOCKER_TAG:="fython:tests"

bootstrap-with-docker:
	DOCKER_BUILDKIT=1 docker build -f devtools/Dockerfile -t $(BOOTSTRAP_DOCKER_TAG) --target bootstrap .

.ONESHELL:
compile-project:
	# USAGE:
	# > make compile-project path=/home/joao/fython/example
	DOCKER_BUILDKIT=1 docker build -f devtools/Dockerfile -t $(COMPILER_DOCKER_TAG) --target compiler .
	DOCKER_BUILDKIT=1 docker run --env PROJET_FOLDER=/project$(path) -v $(path):/project$(path) $(COMPILER_DOCKER_TAG)

.ONESHELL:
run-tests:
	DOCKER_BUILDKIT=1 docker build -f devtools/Dockerfile -t $(TESTS_DOCKER_TAG) --target tests .
	DOCKER_BUILDKIT=1 docker run $(TESTS_DOCKER_TAG)

.ONESHELL:
build-shell:
	DOCKER_BUILDKIT=1 docker build -f devtools/Dockerfile -t $(SHELL_DOCKER_TAG) --target shell .

.ONESHELL:
shell-current-src:
	$(MAKE) build-shell
	DOCKER_BUILDKIT=1 docker run -it $(SHELL_DOCKER_TAG)

.ONESHELL:
project-shell:
	# > compile-project-and-open-shell path=/home/joao/fython/example
	$(MAKE) compile-project path=$(path)
	$(MAKE) build-shell
	DOCKER_BUILDKIT=1 docker run -it --env ADITIONAL_PATHS=/project$(path)/_compiled -v $(path):/project$(path) $(SHELL_DOCKER_TAG)
