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

# compile all the modules idependitly
for FILE_PATH in $ALL_FILES_PATH
do
  ERL_COMMAND_CALL="application:start(compiler), application:start(elixir), 'Fython.Core.Code':compile_project_file(<<"'"'${CURRENT_DIR}'"'">>, <<"'"'${FILE_PATH}'"'">>, "'"'${BOOTSTRAP_FOLDER}'"'"), init:stop()."
  erl -pa $PRE_COMPILER  -noshell -eval "$ERL_COMMAND_CALL"
done

echo "Finished"