CURRENT_DIR=$(pwd)

ALL_FILES_PATH=$(find "$(pwd)" -name '*.fy')

PRE_COMPILER=${1:-"./_compiled"}
BOOTSTRAP_FOLDER=${2:-"_bootstrap"}

ELIXIR_PATH='/usr/lib/elixir/lib/elixir/ebin'

echo "Bootstraping"
echo "pre compiler: "$CURRENT_DIR/$PRE_COMPILER
echo "destine folder: "$CURRENT_DIR/$BOOTSTRAP_FOLDER
echo ""

rm -rf $BOOTSTRAP_FOLDER || 0
mkdir $BOOTSTRAP_FOLDER

# copy elixir modules
cp -r $ELIXIR_PATH/* $CURRENT_DIR/$BOOTSTRAP_FOLDER

exec_in_erl () {
  FILE_PATH=$1
  ERL_COMMAND_CALL="application:start(compiler), application:start(elixir), 'Elixir.Code':compiler_options(#{ignore_module_conflict => true}), 'Fython.Core.Code':compile_project_file(<<"'"'${CURRENT_DIR}'"'">>, <<"'"'${FILE_PATH}'"'">>, "'"'${BOOTSTRAP_FOLDER}'"'"), init:stop()."
  erl -pa $PRE_COMPILER  -noshell -eval "$ERL_COMMAND_CALL"
}

# compile all the modules idependitly
for FILE_PATH in $ALL_FILES_PATH; do exec_in_erl $FILE_PATH & done
wait

echo "Finished"