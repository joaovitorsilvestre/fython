def compile_project(project_path):
    compile_project(
        project_path, Elixir.Enum.join([project_path, '/', "_compiled"])
    )

def compile_project(project_path, destine):
    # start elixir compiler
    Erlang.application.start(:compiler)
    Erlang.application.start(:elixir)

    # Ensure compiled folder is created
    Elixir.File.mkdir_p!(destine)

    [project_path, "**/*.fy"]
        |> Elixir.Enum.join('/')
        |> Elixir.Path.wildcard()
        |> Elixir.Enum.map(lambda file_full_path:
            compile_project_file(project_path, file_full_path, destine)
        )


def compile_project_file(project_root, file_full_path, destine_compiled):
    module_name = get_module_name(project_root, file_full_path)

    destine_compiled = Elixir.Enum.join([destine_compiled])

    # Ensure compiled folder is created
    Elixir.File.mkdir_p!(destine_compiled)

    Elixir.IO.puts(Elixir.Enum.join(["Compiling module: ", module_name]))

    [state, quoted] = lexer_parse_convert_file(
        module_name, file_full_path, Elixir.File.read(file_full_path) |> Elixir.Kernel.elem(1)
    )

    case Elixir.Map.get(state, "error"):
        None ->
            # Its super important to use this Module.create function
            # to ensure that our module binary will not have
            # Elixir. in the begin of the module name
            (_, _, binary, _) = Elixir.Module.create(
                Elixir.String.to_atom(module_name), quoted, Elixir.Macro.Env.location(__ENV__)
            )

            # just for consulting
            destine_ex = Elixir.Enum.join([destine_compiled, "/", module_name, ".ex"])
            destine_beam = Elixir.Enum.join([destine_compiled, "/", module_name, ".beam"])

            Elixir.File.write(destine_ex, Elixir.Macro.to_string(quoted))
            Elixir.File.write(destine_beam, binary, mode=:binary)
        _ ->
            Elixir.IO.puts("Compilation error:")
            Elixir.IO.puts("file path:")
            Elixir.IO.puts(file_full_path)
            text = Elixir.File.read(file_full_path) |> Elixir.Kernel.elem(1)
            Core.Errors.Utils.print_error(module_name, state, text)
            :error


def lexer_parse_convert_file(module_name, files_full_path,  text):
    lexer_parse_convert_file(module_name, files_full_path,  text, [])

def lexer_parse_convert_file(module_name, files_full_path,  text, env):
    lexed = Core.Lexer.execute(text)

    state = case Elixir.Map.get(lexed, "error"):
        None ->
            tokens = Elixir.Map.get(lexed, "tokens")
            Core.Parser.execute(files_full_path, tokens, env)
        _ ->
            lexed

    # 2º Convert each node from json to Fython format
    case Elixir.Map.get(state, 'error'):
        None ->
            ast = Elixir.Map.get(state, 'node')
            [state, Core.Generator.Conversor.convert(ast)]
        _ -> [state, None]


def get_module_name(project_full_path, file_full_path):
    # input > /home/joao/fythonproject/module/utils.fy
    # output > ModuleA.Utils

    # if file name is __init__.fy
    # we wil remove this name and the module name passes to be
    # the name of this file parent folder

    case Elixir.String.starts_with?(file_full_path, project_full_path):
        True -> None
        False -> raise "File fullpath doent match project full path"

    name = Elixir.String.replace_prefix(file_full_path, project_full_path, "")

    # remove / from the start of the name
    name = case Elixir.String.graphemes(name) |> Elixir.Enum.at(0):
        "/" -> Elixir.String.graphemes(name) |> Elixir.Enum.slice(Elixir.Range.new(1, -1)) |> Elixir.Enum.join()
        _ -> name

    # remove .fy
    final = name
        |> Elixir.String.graphemes()
        |> Elixir.Enum.split(-3)
        |> Elixir.Kernel.elem(0)
        |> Elixir.Enum.join()
        |> Elixir.String.split("/")
        |> Elixir.Enum.map(lambda i: Elixir.String.capitalize(i))

    final = case Elixir.List.last(final):
        "__init__" ->
            final
                |> Elixir.List.pop_at(-1)
                |> Elixir.Kernel.elem(1)
                |> Elixir.Enum.join('.')
        _ -> final |> Elixir.Enum.join('.')

    Elixir.Enum.join(["Fython.", final])


def parallel_map(collection, func):
    collection
        |> Elixir.Enum.map(lambda i: Elixir.Task.async(lambda: func(i)))
        |> Elixir.Enum.map(lambda i: Elixir.Task.await(i, :infinity))
