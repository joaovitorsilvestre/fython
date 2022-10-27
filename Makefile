SHELL := /bin/bash

# makefile location
ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
# fython src folder
SRC_DIR:="$(ROOT_DIR)/src"

bootstrap-with-docker:
	docker build -f devtools/Dockerfile -t fython .

shell-current-src:
	docker build -f devtools/Dockerfile -t fython --target fython_shell .
	docker run -it fython_shell

.ONESHELL:
compile-project:
	# USAGE:
	# > make compile-project path=/home/joao/fython/example
	docker build -f devtools/Dockerfile -t fython --target compile_project .
	docker run --env PROJET_FOLDER=/project -v $(path):/project fython

.ONESHELL:
run-tests:
	docker build -f devtools/Dockerfile -t fython --target tests .
	docker run -it fython