-module(fython).
-export([eval_string/1, bootstrap1/3, bootstrap2/3]).

eval_string(Code) ->
    'Fython.Core':eval_string(Code).

prefix_bootstrap() ->
    "Bootstrap".

bootstrap1(FythonCodePath, Destine, ElixirBeamsPath) ->
    'Fython.Core.Code':compile_project(FythonCodePath, Destine, prefix_bootstrap()),
    copy_files_from_dir_to_another(ElixirBeamsPath, binary_to_string(Destine)).

bootstrap2(FythonCodePath, Destine, ElixirBeamsPath) ->
    Module = list_to_atom("Fython." ++ prefix_bootstrap() ++ ".Core.Code"),
    Module:compile_project(FythonCodePath, Destine, nil),
    copy_files_from_dir_to_another(ElixirBeamsPath, binary_to_string(Destine)).

binary_to_string(Bin) ->
    % converts <<"abc">> to "abc"
    lists:nth(1, io_lib:format("~s",[Bin])).

copy_files_from_dir_to_another(SourceDir, DestineDir) ->
    'Elixir.File':'cp_r!'(SourceDir, DestineDir).
