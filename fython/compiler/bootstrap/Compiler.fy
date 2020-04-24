import IO, System, File, ParserNode, Utils


def compile_project(project_path):
    compiled_folder = [project_path, "compiled"] |> Enum.join('/')

    # Ensure compiled folder is created
    File.mkdir_p!(compiled_folder)

    # Copy elixir beams to folder
    copy_elixir_beams(project_path)

    # Add elixir dependencies
    Code.append_path(compiled_folder)

    # Compile project and save files into subfolder 'compiled'
    all_modules_compiled = compile_project_to_binary(project_path)

    all_modules_compiled
        |> Enum.map(lambda modulename_n_coted:
            module_name = modulename_n_coted |> elem(0)
            compiled = modulename_n_coted |> elem(1)

            File.write(
                Utils.join_str([project_path, "/compiled/", module_name, ".beam"]), compiled, mode=:binary
            )
        )


def copy_elixir_beams(project_path):
    compiled_folder = Enum.join([project_path, 'compiled'], '/')

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


def compile_project_to_binary(directory_path):
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
        |> Enum.map(lambda full_path:
            module_name = get_module_name(directory_path, full_path)

            IO.puts(Enum.join(["Compiling module: ", module_name]))

            IO.puts("* lexing")
            compiled_n_error = lexer_and_parse_file_content_in_python(
                module_name, full_path
            )

            compiled = compiled_n_error |> Enum.at(0)
            error = compiled_n_error |> Enum.at(1)

            case error:
                None -> None
                _ ->
                    IO.puts("Compilation error:")
                    IO.puts(error)

            [module_name, compiled]
        )
        |> Enum.map(lambda modulename_n_content:
            IO.puts("* compiling")
            module_name = modulename_n_content |> Enum.at(0)
            compiled = modulename_n_content |> Enum.at(1)

            module = ParserNode.convert_module_to_ast(module_name, compiled)

            IO.inspect(module)

            quoted = module
                |> Code.eval_string()
                |> Code.compile_quoted()
                |> Enum.at(0)
        )


def lexer_and_parse_file_content_in_python(module_name, file_full_path):
    # this function will lexer and parser using python for now
    # when the day to write the lexer and parser in python has come
    # this function will be responsible to call all the necessary functions

    # 1º Ask python for the json lexed and parsed
    command = [
        'import sys;',
        "sys.path.insert(0, '/home/joao/fython');",
        'from fython.core import get_lexed_and_jsonified;',
        'a = ',
        "'", file_full_path ,"';",
        'print(get_lexed_and_jsonified(a))'
    ] |> Enum.join('')

    json = System.cmd("python3.6", ["-c", command])
        |> elem(0)
        |> Jason.decode()
        |> elem(1)

    ast = json |> Map.get("ast") |> Jason.decode() |> elem(1)
    error = json |> Map.get("error")

    # 2º Convert each node from json to Fython format
    case error:
        None -> [ParserNode.convert(ast), error]
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
