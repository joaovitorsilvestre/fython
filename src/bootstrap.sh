rm -rf _bootstrap || 0
mkdir _bootstrap

# Compile all project as
erl -pa ./_compiled -noshell -eval 'application:start(compiler),application:start(elixir),'"'"'Fcore.Generator.Compiler'"'"':compile_project("/home/joao/fython/src", "_bootstrap").' -s erlang halt