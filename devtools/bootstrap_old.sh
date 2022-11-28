#!/bin/bash
set -eo pipefail # stop if any error

compile () {
  # We use the _COMP sufix to avoid conflict with external variables
  # (variabls of the shell that is running this script)
  SRC_DIR_COMP=$1
  DESTINE_PATH_COMP=$2
  PATH_FYTHON_TO_USE_AS_BOOTSTRAPER_COMP=$3
  ELIXIR_BEAMS_PATH_COMP=$4
  COMPILE_IN_PARALEL=true

  [[ -z "$SRC_DIR_COMP" ]] && echo "Missing src dir of fython" && exit 1
  [[ -z "$DESTINE_PATH_COMP" ]] && echo "Missing destine path of bootstrap" && exit 1
  [[ -z "$PATH_FYTHON_TO_USE_AS_BOOTSTRAPER_COMP" ]] && echo "Missing path of previous fython to use as bootstraper" && exit 1
  [[ -z "$ELIXIR_BEAMS_PATH_COMP" ]] && echo "Missing elixir beams path" && exit 1

  ALL_FILES_PATH_COMP=$(find $SRC_DIR_COMP -name '*.fy')

  echo "Destine folder: $DESTINE_PATH_COMP"
  rm -rf $DESTINE_PATH_COMP/*

  cd $ELIXIR_BEAMS_PATH_COMP && cp -r . "$DESTINE_PATH_COMP" && cd /

  EXIT_CODES_PATH=/tmp/bootstra_exit_codes
  rm -rf $EXIT_CODES_PATH
  mkdir $EXIT_CODES_PATH

  for FILE_PATH in $ALL_FILES_PATH_COMP; do
      ERL_COMMAND_CALL="application:start(compiler), application:start(elixir), 'Elixir.Code':compiler_options(#{ignore_module_conflict => true}), 'Fython.Core.Code':compile_project_file(<<"'"'$SRC_DIR_COMP'"'">>, <<"'"'${FILE_PATH}'"'">>, "'"'$DESTINE_PATH_COMP'"'", true), init:stop().";
      FILE_PATH_SCAPED=$(echo $FILE_PATH | sed 's/\//SEPARATOR/g')

      if [ "$COMPILE_IN_PARALEL" = true ] ; then
        erl -pa $PATH_FYTHON_TO_USE_AS_BOOTSTRAPER_COMP  -noshell -eval "$ERL_COMMAND_CALL" || echo $? > $EXIT_CODES_PATH/$FILE_PATH_SCAPED &
      else
        erl -pa $PATH_FYTHON_TO_USE_AS_BOOTSTRAPER_COMP  -noshell -eval "$ERL_COMMAND_CALL" || echo $? > $EXIT_CODES_PATH/$FILE_PATH_SCAPED
      fi
  done
  wait

  # when running in parallel we need this to ensure that all comands returned 0 code
  # otherwise this script would return 0 code even when some erl command failed
  for RESULT in `ls $EXIT_CODES_PATH`; do
    ORIGINAL_PATH=$(echo $RESULT | sed 's/SEPARATOR/\//g')
    RESULT=$(cat $EXIT_CODES_PATH/$RESULT)
    if [[ $RESULT -ne "0" ]]; then
       echo "Bootstrap Failed --------------------"
       echo "Failed to compile files: $ORIGINAL_PATH"
       echo "-------------------------------------"
       exit 1
    fi
  done
  echo "Bootstraped with success"
}

$*
