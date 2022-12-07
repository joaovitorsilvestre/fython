-module(fython).
-export([eval_string/1, bootstrap/2, bootstrap1/3, bootstrap2/4]).

eval_string(Code) ->
    'Fython.Core':eval_string(Code).

bootstrap1(FythonCodePath, Destine, Prefix) ->
    'Fython.Core.Code':compile_project(FythonCodePath, Destine, Prefix).

bootstrap2(FythonCodePath, Destine, Prefix, ElixirBeamsPath) ->
    clean_dir(Destine),
    Module = list_to_atom("Fython." ++ Prefix ++ ".Core.Code"),
    Module:compile_project(FythonCodePath, Destine, nil),
    copy_elixir_beams_to_folder(ElixirBeamsPath, binary_to_string(Destine)).

binary_to_string(Bin) ->
    % converts <<1,2,3>> to "123"
    lists:nth(1, io_lib:format("~s",[<<"aa">>])).

bootstrap(FythonCodePath, ElixirBeamsPath) ->
    Prefix = "Bootstrap",
    FirstCompiledFolder = "/test_compiled1",
    SecondCompiledFolder = "/test_compiled1",

    % 1º Compile with a module prefix to prevent modules overriding
    clean_dir(FirstCompiledFolder),
    'Fython.Core.Code':compile_project(FythonCodePath, FirstCompiledFolder, Prefix),
    copy_elixir_beams_to_folder(ElixirBeamsPath, FirstCompiledFolder),

    % 2º Bootstrap again using previous step, but without the prefix this time
    % so we have the final bootstraped beams
    clean_dir(SecondCompiledFolder),
    Module = list_to_atom("Fython." ++ Prefix ++ ".Core.Code"),
    Module:compile_project(FythonCodePath, SecondCompiledFolder, nil),
    copy_elixir_beams_to_folder(ElixirBeamsPath, SecondCompiledFolder),
    file:del_dir(FirstCompiledFolder, []).

clean_dir(Dir) ->
    file:del_dir(Dir),
    file:make_dir(Dir).

copy_elixir_beams_to_folder(ElixirBeamsPath, Destine) ->
    {ok, Filenames} = file:list_dir(ElixirBeamsPath),

    lists:map(fun(Filename) ->
        file:copy(Filename, Destine ++ "/" ++ Filename, [overwrite]),
        io:format("Copied ~s to ~s~n", [Filename, Destine ++ "/" ++ Filename])
    end,Filenames).
