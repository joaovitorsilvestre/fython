def compile_project(project_path):
    compile_project(project_path, "_compiled")


def compile_project(project_path, destine):
    compiled_folder = [project_path, destine] |> Enum.join('/')

    # Ensure compiled folder is created
    File.mkdir_p!(compiled_folder)

    compile_project_to_binary(project_path, compiled_folder)


def compile_project_to_binary(directory_path, compiled_folder):
    # Return a list of each module compiled into elixir AST in binary
    # read to be evaluated in Elixir
    # Ex:
    # iex> Compiler.compile_project(ABSOLUTE_PATH_TO_PROJECT_FOLDER)
    # exit the shell
    # go to compiled folder and start iex again.
    # Now, you should be able to call any module of this project in iex

    [directory_path, "**/*.fy"]
        |> Enum.join('/')
        |> Path.wildcard()
        |> Enum.sort()
        |> parallel_map(lambda full_path:
            module_name = get_module_name(directory_path, full_path)

            IO.puts(Enum.join(["Compiling module: ", module_name]))

            state_n_converted = lexer_parse_convert_file(
                module_name, File.read(full_path) |> elem(1)
            )

            state = Enum.at(state_n_converted, 0)
            converted = Enum.at(state_n_converted, 1)

            case Map.get(state, "error"):
                None ->
                    (quoted, _) = Code.eval_string(converted)

                    # Its super important to use this Module.create function
                    # to ensure that our module binary will not have
                    # Elixer. in the begin of the module name
                    (_, _, binary, _) = Module.create(
                        String.to_atom(module_name), quoted, Macro.Env.location(__ENV__)
                    )

                    File.write(
                        Enum.join([compiled_folder, "/", module_name, ".beam"]),
                        binary,
                        mode=:binary
                    )
                _ ->
                    IO.puts("Compilation error:")
                    IO.puts("file path:")
                    IO.puts(full_path)
                    text = File.read(full_path) |> elem(1)
                    Fcore.Errors.Utils.print_error(module_name, state, text)
                    raise "end"
        )


def lexer_parse_convert_file(module_name, text):
    lexed = Fcore.Lexer.execute(text)

    state = case Map.get(lexed, "error"):
        None ->
            tokens = Map.get(lexed, "tokens")
            Fcore.Parser.execute(tokens)
        _ ->
            lexed


    ast = Map.get(state, 'node')

    # 2º Convert each node from json to Fython format
    case Map.get(state, 'error'):
        None -> [state, Fcore.Generator.Conversor.convert(ast)]
        _ -> [state, None]


def get_module_name(project_full_path, module_full_path):
    # input > /home/joao/fythonproject/module/utils.fy
    # output > ModuleA.Utils

    # if file name is __init__.fy
    # we wil remove this name and the module name passes to be
    # the name of this file parent folder

    directory_path = project_full_path |> String.replace(".", "\.")

    regex = Regex.compile(Enum.join(["^", project_full_path, "/"]))
        |> elem(1)

    name = Regex.replace(regex, module_full_path, "")
        |> String.replace("/", ".")

    final = Regex.compile("\.fy$") |> elem(1)
        |> Regex.replace(name, "")
        |> String.split('.')
        |> Enum.map(lambda i: String.capitalize(i))

    case final |> List.last():
        "__init__" ->
            final
                |> List.pop_at(-1)
                |> elem(1)
                |> Enum.join('.')
        _ -> final |> Enum.join('.')

def parallel_map(collection, func):
    collection
        |> Enum.map(lambda i: Task.async(lambda: func(i)))
        |> Enum.map(lambda i: Task.await(i, :infinity))
