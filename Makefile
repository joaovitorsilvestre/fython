SHELL := /bin/bash

# makefile location
ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
# fython src folder
SRC_DIR:="$(ROOT_DIR)/src"
TESTS_PATH:="$(ROOT_DIR)/tests"

BOOTSTRAP_DOCKER_TAG:="fython:bootstrap"
COMPILER_DOCKER_TAG:="fython:compiler"
SHELL_DOCKER_TAG:="fython:shell"
FYTEST_DOCKER_TAG:="fython:fytest"
TESTS_DOCKER_TAG:="fython:tests"


bootstrap-with-docker:
	docker build -f devtools/Dockerfile -t $(BOOTSTRAP_DOCKER_TAG) --target bootstrap . || exit 1

.ONESHELL:
compile-project:
	# USAGE:
	# > make compile-project path=/home/joao/fython/example
	DOCKER_BUILDKIT=1 docker build -f devtools/Dockerfile -t $(COMPILER_DOCKER_TAG) --target compiler . || exit 1
	DOCKER_BUILDKIT=1 docker run --env PROJET_FOLDER=/project$(path) -v $(path):/project$(path) $(COMPILER_DOCKER_TAG) || exit 1

.ONESHELL:
run-tests:
	# > make run-tests
	$(MAKE) build-fytest
	DOCKER_BUILDKIT=1 docker run -e FOLDER=$(TESTS_PATH) -v $(TESTS_PATH):$(TESTS_PATH) $(FYTEST_DOCKER_TAG) || exit 1

.ONESHELL:
build-shell:
	DOCKER_BUILDKIT=1 docker build -f devtools/Dockerfile -t $(SHELL_DOCKER_TAG) --target shell .  || exit 1

.ONESHELL:
build-fytest:
	DOCKER_BUILDKIT=1 docker build -f devtools/Dockerfile -t $(FYTEST_DOCKER_TAG) --target fytest .  || exit 1

.ONESHELL:
shell-current-src:
	$(MAKE) build-shell
	DOCKER_BUILDKIT=1 docker run -it $(SHELL_DOCKER_TAG) || exit 1

.ONESHELL:
project-shell:
	# > project-shell path=/home/joao/fython/example
	$(MAKE) compile-project path=$(path)
	$(MAKE) build-shell
	DOCKER_BUILDKIT=1 docker run -it --env ADITIONAL_PATHS=/project$(path)/_compiled -v $(path):/project$(path) $(SHELL_DOCKER_TAG) || exit 1

project-bash:
	# > project-bash path=/home/joao/fython/example
	$(MAKE) compile-project path=$(path)
	DOCKER_BUILDKIT=1 docker run -it --env ADITIONAL_PATHS=/project$(path)/_compiled -v $(path):/project$(path) $(SHELL_DOCKER_TAG) bash  || exit 1
