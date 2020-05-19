def compile_project(project_path):
    compile_project(project_path, "_compiled")

def compile_project(project_path, destine):
    compiled_folder = [project_path, destine] |> Enum.join('/')

    # Ensure compiled folder is created
    File.mkdir_p!(compiled_folder)
    File.mkdir_p!(Enum.join([compiled_folder, '/', 'exs']))

    # Copy elixir beams to folder
    copy_elixir_beams(compiled_folder)

    # Add elixir dependencies
    Code.append_path(compiled_folder)

    # Compile project and save files into subfolder 'compiled'
    all_files_path = compile_project_to_binary(project_path, compiled_folder)

    Kernel.ParallelCompiler.compile_to_path(all_files_path, compiled_folder)


def copy_elixir_beams(compiled_folder):
    elixir_path = '/usr/lib/elixir/lib/elixir/ebin'

    case File.exists?(elixir_path):
        True -> Enum.join([elixir_path, '*'], '/')
            |> Path.wildcard()
            |> Enum.each(lambda beam_file:
                file_name = beam_file
                    |> String.split('/')
                    |> List.last()

                File.cp!(beam_file, Enum.join([compiled_folder, file_name], '/'))
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
        |> Enum.join('/')
        |> Path.wildcard()
        |> Enum.sort()
        |> parallel_map(lambda full_path:
            module_name = get_module_name(directory_path, full_path)

            IO.puts(Enum.join(["Compiling module: ", module_name]))

            IO.puts("* lexing and parsing")
            state_n_converted = lexer_parse_convert_file(
                module_name, File.read(full_path) |> elem(1)
            )

            state = Enum.at(state_n_converted, 0)
            converted = Enum.at(state_n_converted, 1)

            case Map.get(state, "error"):
                None ->
                    module = Fcore.Generator.Conversor.convert_module_to_ast(
                        module_name, converted
                    )

                    #IO.inspect('elixir str:')
                    #IO.inspect(module)

                    # TODO save in a file to need to compile is pretty ugly
                    # TODO we need to fix this
                    elixir_str = Macro.to_string(module)
                        |> Code.eval_string()
                        |> elem(0)
                        |> Code.eval_string()
                        |> Macro.to_string()

                    ex_path = Enum.join([compiled_folder, "/exs/", module_name, ".ex"])

                    File.write(ex_path, elixir_str)
                    ex_path
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
