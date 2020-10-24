exec_in_erl () {
	SRC_DIR=$1
	FILE_PATH=$2
	BOOTSTRAP_FOLDER=$3
	PRE_COMPILER=$4
  ERL_COMMAND_CALL="application:start(compiler), application:start(elixir), 'Elixir.Code':compiler_options(#{ignore_module_conflict => true}), 'Fython.Core.Code':compile_project_file(<<"'"'${SRC_DIR}'"'">>, <<"'"'${FILE_PATH}'"'">>, "'"'${BOOTSTRAP_FOLDER}'"'"), init:stop()."
  sudo erl -pa $PRE_COMPILER  -noshell -eval "$ERL_COMMAND_CALL"
	echo "SRC_DIR: " $SRC_DIR
	echo "FILE_PATH: " $FILE_PATH
	echo "BOOTSTRAP_FOLDER: " $BOOTSTRAP_FOLDER
	echo "PRE_COMPILER: " $PRE_COMPILER
	echo '-----'
}

# Allows to call a function based on arguments passed to the script
$*