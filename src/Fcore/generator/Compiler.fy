def compile_project(project_path):
    compile_project(project_path, "_compiled")


def compile_project(project_path, destine):
    compiled_folder = [project_path, destine] |> Elixir.Enum.join('/')

    # Ensure compiled folder is created
    Elixir.File.mkdir_p!(compiled_folder)

    # Copy elixir beams to folder
    copy_elixir_beams(compiled_folder)

    compile_project_to_binary(project_path, compiled_folder)


def copy_elixir_beams(compiled_folder):
    elixir_path = '/usr/lib/elixir/lib/elixir/ebin'

    case Elixir.File.exists?(elixir_path):
        True -> Elixir.Enum.join([elixir_path, '*'], '/')
            |> Elixir.Path.wildcard()
            |> Elixir.Enum.each(lambda beam_file:
                file_name = beam_file
                    |> Elixir.String.split('/')
                    |> Elixir.List.last()

                Elixir.File.cp!(beam_file, Elixir.Enum.join([compiled_folder, file_name], '/'))
            )
        False -> :error

def compile_project_to_binary(directory_path, compiled_folder):
    # Return a list of each module compiled into elixir AST in binary
    # read to be evaluated in Elixir
    # Ex:
    # iex> Compiler.compile_project(ABSOLUTE_PATH_TO_PROJECT_FOLDER)
    # exit the shell
    # go to compiled folder and start iex again.
    # Now, you should be able to call any module of this project in iex

    [directory_path, "**/*.fy"]
        |> Elixir.Enum.join('/')
        |> Elixir.Path.wildcard()
        |> Elixir.Enum.sort()
        |> Elixir.Enum.map(lambda full_path:
            module_name = get_module_name(directory_path, full_path)

            Elixir.IO.puts(Elixir.Enum.join(["Compiling module: ", module_name]))

            state_n_converted = lexer_parse_convert_file(
                module_name, Elixir.File.read(full_path) |> Elixir.Kernel.elem(1)
            )

            state = Elixir.Enum.at(state_n_converted, 0)
            converted = Elixir.Enum.at(state_n_converted, 1)

            case Elixir.Map.get(state, "error"):
                None ->
                    (quoted, _) = Elixir.Code.eval_string(converted)

                    # Its super important to use this Module.create function
                    # to ensure that our module binary will not have
                    # Elixir. in the begin of the module name
                    (_, _, binary, _) = Elixir.Module.create(
                        Elixir.String.to_atom(module_name), quoted, Elixir.Macro.Env.location(__ENV__)
                    )

                    Elixir.File.write(
                        Elixir.Enum.join([compiled_folder, "/", module_name, ".beam"]),
                        binary,
                        mode=:binary
                    )
                _ ->
                    Elixir.IO.puts("Compilation error:")
                    Elixir.IO.puts("file path:")
                    Elixir.IO.puts(full_path)
                    text = Elixir.File.read(full_path) |> Elixir.Kernel.elem(1)
                    Fcore.Errors.Utils.print_error(module_name, state, text)
                    raise "end"
        )


def lexer_parse_convert_file(module_name, text):
    lexed = Fcore.Lexer.execute(text)

    state = case Elixir.Map.get(lexed, "error"):
        None ->
            tokens = Elixir.Map.get(lexed, "tokens")
            Fcore.Parser.execute(tokens)
        _ ->
            lexed


    ast = Elixir.Map.get(state, 'node')

    # 2º Convert each node from json to Fython format
    case Elixir.Map.get(state, 'error'):
        None -> [state, Fcore.Generator.Conversor.convert(ast)]
        _ -> [state, None]


def get_module_name(project_full_path, module_full_path):
    # input > /home/joao/fythonproject/module/utils.fy
    # output > ModuleA.Utils

    # if file name is __init__.fy
    # we wil remove this name and the module name passes to be
    # the name of this file parent folder

    regex = Elixir.Regex.compile(Elixir.Enum.join(["^", project_full_path, "/"]))
        |> Elixir.Kernel.elem(1)

    name = Elixir.Regex.replace(regex, module_full_path, "")
        |> Elixir.String.replace("/", ".")

    final = Elixir.Regex.compile("\.fy$") |> Elixir.Kernel.elem(1)
        |> Elixir.Regex.replace(name, "")
        |> Elixir.String.split('.')
        |> Elixir.Enum.map(lambda i: Elixir.String.capitalize(i))

    case final |> Elixir.List.last():
        "__init__" ->
            final
                |> Elixir.List.pop_at(-1)
                |> Elixir.Kernel.elem(1)
                |> Elixir.Enum.join('.')
        _ -> final |> Elixir.Enum.join('.')

def parallel_map(collection, func):
    collection
        |> Elixir.Enum.map(lambda i: Task.async(lambda: func(i)))
        |> Elixir.Enum.map(lambda i: Task.await(i, :infinity))
