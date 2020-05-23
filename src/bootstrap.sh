CURRENT_DIR=$(pwd)

ALL_FILES_PATH=$(find "$(pwd)" -name '*.fy')

BOOTSTRAP_FOLDER="_bootstrap"

echo "Bootstraping"
echo "destine folder: "$CURRENT_DIR/$BOOTSTRAP_FOLDER
echo ""

rm -rf _bootstrap || 0
mkdir _bootstrap

for FILE_PATH in $ALL_FILES_PATH
do
  ERL_COMMAND_CALL="application:start(compiler), application:start(elixir), 'Fython.Core.Code':compile_project_file(<<"'"'${CURRENT_DIR}'"'">>, <<"'"'${FILE_PATH}'"'">>, "'"'${BOOTSTRAP_FOLDER}'"'"), init:stop()."
  erl -pa ./_new_compiler2  -noshell -eval "$ERL_COMMAND_CALL"
done

echo "Finished"