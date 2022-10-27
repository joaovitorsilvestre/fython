#!/bin/bash

SRC_DIR=$1
DESTINE_PATH=$2
PATH_FYTHON_TO_USE_AS_BOOTSTRAPER=$3
ELIXIR_BEAMS_PATH=$4

ALL_FILES_PATH=$(find /src -name '*.fy')

echo "Bootstraping using Fython $VERSION_TO_USE_AS_BOOTSTRAPER"
echo "Destine folder: DESTINE_PATH"
mkdir $DESTINE_PATH
cp -r $ELIXIR_BEAMS_PATH/* $DESTINE_PATH
SRC_DIR=/src
for FILE_PATH in $ALL_FILES_PATH; do
    ERL_COMMAND_CALL="application:start(compiler), application:start(elixir), 'Elixir.Code':compiler_options(#{ignore_module_conflict => true}), 'Fython.Core.Code':compile_project_file(<<"'"'$SRC_DIR'"'">>, <<"'"'${FILE_PATH}'"'">>, "'"'$DESTINE_PATH'"'"), init:stop().";
    erl -pa $PATH_FYTHON_TO_USE_AS_BOOTSTRAPER  -noshell -eval "$ERL_COMMAND_CALL";
done