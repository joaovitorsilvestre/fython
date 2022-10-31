SHELL := /bin/bash

# makefile location
ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
# fython src folder
SRC_DIR:="$(ROOT_DIR)/src"

bootstrap-with-docker:
	@DOCKER_TAG="fython:bootstrap"
	docker build -f devtools/Dockerfile -t $$DOCKER_TAG --target base .

.ONESHELL:
compile-project:
	# USAGE:
	# > make compile-project path=/home/joao/fython/example
	@DOCKER_TAG="fython:compiler"
	docker build -f devtools/Dockerfile -t $$DOCKER_TAG --target compiler .
	docker run --env PROJET_FOLDER=/project -v $(path):/project $$DOCKER_TAG

.ONESHELL:
run-tests:
	@DOCKER_TAG="fython:tests"
	docker build -f devtools/Dockerfile -t $$DOCKER_TAG --target tests .
	docker run $$DOCKER_TAG


.ONESHELL:
shell-current-src:
	@DOCKER_TAG="fython:shell"
	docker build -f devtools/Dockerfile -t $$DOCKER_TAG --target shell .
	docker run -it $$DOCKER_TAG