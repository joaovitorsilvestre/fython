def compile_project(project_path):
    compile_project(project_path, "_compiled")

def compile_project(project_path, destine):
    compiled_folder = [project_path, destine] |> Enum.join('/')

    # Ensure compiled folder is created
    File.mkdir_p!(compiled_folder)
    File.mkdir_p!(Enum.join([compiled_folder, '/', 'exs']))

    # Copy Jason dependency and add to path
    # We still use it in string conversor to handle scape char
    # and double cote inside double quote string
    copy_jason_beams(compiled_folder)

    # Copy elixir beams to folder
    copy_elixir_beams(compiled_folder)

    # Add elixir dependencies
    Code.append_path(compiled_folder)

    # Compile project and save files into subfolder 'compiled'
    all_files_path = compile_project_to_binary(project_path, compiled_folder)

    Kernel.ParallelCompiler.compile_to_path(all_files_path, compiled_folder)

    #all_modules_compiled
    #    |> Enum.map(lambda modulename_n_coted:
    #        module_name = modulename_n_coted |> elem(0) |> to_string()
    #        compiled = modulename_n_coted |> elem(1)
    #
    #        IO.inspect('saving file')
    #        IO.inspect(Enum.join([project_path, "/compiled/", module_name, ".beam"]))
    #
    #        File.write(
    #            Enum.join([compiled_folder, "/", module_name, ".beam"]), compiled, mode=:binary
    #        )
    #    )


def copy_elixir_beams(compiled_folder):
    elixir_path = '/usr/lib/elixir/lib/elixir/ebin'

    case File.exists?(elixir_path):
        True -> Enum.join([elixir_path, '*.beam'], '/')
            |> Path.wildcard()
            |> Enum.each(lambda beam_file:
                file_name = beam_file
                    |> String.split('/')
                    |> List.last()

                File.cp!(beam_file, Enum.join([compiled_folder, file_name], '/'))
            )
        False -> :error

def copy_jason_beams(compiled_folder):
    jason_folder = Enum.join([
        '/home/joao/fython/src/core/generator/jason_dep', 'Elixir.Jason.*.beam'
    ], '/')

    jason_folder
        |> Path.wildcard()
        |> Enum.each(lambda beam_file:
            file_name = beam_file
                |> String.split('/')
                |> List.last()

            File.cp!(beam_file, Enum.join([compiled_folder, file_name], '/'))
        )


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
        |> Enum.map(lambda full_path:
            module_name = get_module_name(directory_path, full_path)

            IO.puts(Enum.join(["Compiling module: ", module_name]))

            IO.puts("* lexing and parsing")
            compiled_n_error = lexer_and_parse_file(
                module_name, full_path
            )

            compiled = compiled_n_error |> Enum.at(0)
            error = compiled_n_error |> Enum.at(1)

            case error:
                None ->
                    module = Fcore.Generator.Conversor.convert_module_to_ast(
                        module_name, compiled
                    )

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
                    text = File.read(full_path) |> elem(1)
                    Fcore.Errors.Utils.print_error(module_name, compiled, text)
        )

def lexer_and_parse_file(module_name, file_full_path):
    lexed_parser_state = Fcore.eval_file(module_name, file_full_path)

    ast = Map.get(lexed_parser_state, 'node')
    error = Map.get(lexed_parser_state, 'error')

    # 2º Convert each node from json to Fython format
    case error:
        None -> [Fcore.Generator.Conversor.convert(ast), error]
        _ -> [None, error]

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
