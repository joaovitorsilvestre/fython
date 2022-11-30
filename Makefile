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

.ONESHELL:
bootstrap-with-docker:
	DOCKER_BUILDKIT=1 docker build -f devtools/Dockerfile -t $(BOOTSTRAP_DOCKER_TAG) --target bootstrap . \
		&& docker rm -f fython_bootstrap || true \
		&& docker run \
			--name fython_bootstrap \
			-v $(ROOT_DIR)/bootstraped:/final_bootstrap \
			-e FINAL_PATH='/final_bootstrap' \
			$(BOOTSTRAP_DOCKER_TAG) && echo "Bootstrap finished. Result saved at '$(ROOT_DIR)/bootstraped'" \
		&& docker rm -f fython_bootstrap

compile-project:
	# USAGE:
	# > make compile-project path=/home/joao/fython/example
	DOCKER_BUILDKIT=1 docker build -f devtools/Dockerfile -t $(COMPILER_DOCKER_TAG) --target compiler . \
		&& DOCKER_BUILDKIT=1 docker run --env PROJET_FOLDER=/project$(path) -v $(path):/project$(path) $(COMPILER_DOCKER_TAG)

run-tests:
	# > make run-tests
	$(MAKE) build-fytest \
		&& DOCKER_BUILDKIT=1 docker run -e FOLDER=$(TESTS_PATH) -v $(TESTS_PATH):$(TESTS_PATH) $(FYTEST_DOCKER_TAG)

build-shell:
	DOCKER_BUILDKIT=1 docker build -f devtools/Dockerfile -t $(SHELL_DOCKER_TAG) --target shell .

build-fytest:
	DOCKER_BUILDKIT=1 docker build -f devtools/Dockerfile -t $(FYTEST_DOCKER_TAG) --target fytest .

shell-current-src:
	$(MAKE) build-shell \
		&& DOCKER_BUILDKIT=1 docker run -it $(SHELL_DOCKER_TAG)

project-shell:
	# > project-shell path=/home/joao/fython/example
	$(MAKE) compile-project path=$(path) \
		&& $(MAKE) build-shell\
		&& DOCKER_BUILDKIT=1 docker run -it --env ADITIONAL_PATHS=/project$(path)/_compiled -v $(path):/project$(path) $(SHELL_DOCKER_TAG)

project-bash:
	# > project-bash path=/home/joao/fython/example
	$(MAKE) compile-project path=$(path) \
		&& DOCKER_BUILDKIT=1 docker run -it --env ADITIONAL_PATHS=/project$(path)/_compiled -v $(path):/project$(path) $(SHELL_DOCKER_TAG) bash

compress-to-release:
	cd bootstraped/ && tar -zcvf $(ROOT_DIR)/_compiled.tar.gz * && cd -