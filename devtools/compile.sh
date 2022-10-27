#!/bin/bash
set -e # stop if any error

# We use the _COMP sufix to avoid conflict with external variables
# (variabls of the shell that is running this script)
SRC_DIR_COMP=$1
DESTINE_PATH_COMP=$2
PATH_FYTHON_TO_USE_AS_BOOTSTRAPER_COMP=$3
ELIXIR_BEAMS_PATH_COMP=$4

ALL_FILES_PATH_COMP=$(find $SRC_DIR_COMP -name '*.fy')

echo "Destine folder: $DESTINE_PATH_COMP"
rm -rf $DESTINE_PATH_COMP
mkdir $DESTINE_PATH_COMP

cd $ELIXIR_BEAMS_PATH_COMP && cp -r . "$DESTINE_PATH_COMP" && cd /

for FILE_PATH in $ALL_FILES_PATH_COMP; do
    ERL_COMMAND_CALL="application:start(compiler), application:start(elixir), 'Elixir.Code':compiler_options(#{ignore_module_conflict => true}), 'Fython.Core.Code':compile_project_file(<<"'"'$SRC_DIR_COMP'"'">>, <<"'"'${FILE_PATH}'"'">>, "'"'$DESTINE_PATH_COMP'"'"), init:stop().";
    erl -pa $PATH_FYTHON_TO_USE_AS_BOOTSTRAPER_COMP  -noshell -eval "$ERL_COMMAND_CALL";
done