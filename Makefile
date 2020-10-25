SHELL := /bin/bash
ev=latest

.SILENT: compile, bootstrap

TEMP_FILES = /tmp
THIS_GIT_VERSION := $(shell git tag | tail -1)

INSTALATION_PATH := /opt/fython

# makefile location
ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
# fython src folder
SRC_DIR:="$(ROOT_DIR)/src"

install-from-source:
	$(MAKE) compile-source DESTINE_PATH=$(INSTALATION_PATH)

shell:
	erl -pa $(INSTALATION_PATH) -s 'Fython.Shell' start -noshell

compile-source:
	echo "Bootstraping with version: " $(THIS_GIT_VERSION)
	echo "Destine path: " $(DESTINE_PATH)

	$(eval OUTPUT_ZIP_PATH := $(TEMP_FILES)/fython_$(THIS_GIT_VERSION)_compiled.tar.gz)
	wget https://github.com/joaovitorsilvestre/fython/releases/download/$(THIS_GIT_VERSION)/_compiled.tar.gz -O $(OUTPUT_ZIP_PATH)

	$(eval COMPILED_OUTPUT_PATH := $(TEMP_FILES)/fython_$(THIS_GIT_VERSION)_compiled_local)
	sudo mkdir -p $(COMPILED_OUTPUT_PATH) 2>/dev/null
	sudo tar -xf $(OUTPUT_ZIP_PATH) -C $(COMPILED_OUTPUT_PATH)

	$(MAKE) bootstrap PRE_COMPILER=$(COMPILED_OUTPUT_PATH) DESTINE_PATH=$(DESTINE_PATH)

bootstrap:
	# e.g: make bootstrap PRE_COMPILER=/home/joao/fython/src/_compiled DESTINE_PATH=/home/joao/fython/src/_bootstrap

	$(eval ELIXIR_PATH = "/usr/lib/elixir/lib/elixir/ebin")
	$(eval ALL_FILES_PATH := $(shell find $(SRC_DIR) -name '*.fy'))

	echo "Bootstraping"
	echo "pre compiler: "$(PRE_COMPILER)
	echo "destine folder: "$(DESTINE_PATH)

	sudo rm -rf $(DESTINE_PATH) || 0
	sudo mkdir $(DESTINE_PATH)

	# copy elixir modules
	sudo cp -r $(ELIXIR_PATH)/* $(DESTINE_PATH)

	# compile all the modules idependitly
	for FILE_PATH in $(ALL_FILES_PATH); do ./functions.sh exec_in_erl ${SRC_DIR} $${FILE_PATH} ${DESTINE_PATH} ${PRE_COMPILER}; done

compress-to-release:
	cd $(FOLDER_PATH)/ && tar -zcvf $(ROOT_DIR)/_compiled.tar.gz * && cd -
