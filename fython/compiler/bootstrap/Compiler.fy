import IO, System, File, ParserNode, Utils


def compile_to_file(project_path):
    # Compile project and save files into subfolder 'compiled'

    all_modules_compiled = compile_project_to_ast_string(project_path)

    all_modules_compiled
        |> Enum.map(lambda module:
            quoted = module
                |> Code.eval_string()
                |> elem(0)
                |> Code.compile_quoted()

            result = quoted
                |> Enum.each(lambda module_n_content:
                    module = module_n_content |> Tuple.to_list() |> Enum.at(0)
                    content = module_n_content |> Tuple.to_list() |> Enum.at(1)

                    # TODO allow options.. -> mode: :binary
                    File.write(
                        Utils.join_str(project_path, "/compiled/", module, ".beam"), content
                    )
                )
        )


def compile_project_to_ast_string(directory_path):
    # Return a list of each module compiled into elixir AST
    # read to be evaluated in Elixir
    # Ex:
    # iex> Compiler.compile_project(ABSOLUTE_PATH_TO_PROJECT_FOLDER)
    #    |> Enum.map(fn i -> i |> Code.eval_string |> Code.eval_quoted end)
    # after this, you should be able to call any module of this project in iex

    [directory_path, "*.fy"]
        |> Enum.join('/')
        |> Path.wildcard()
        |> Enum.map(lambda full_path:
            module_name = full_path
                |> String.split('/')
                |> Enum.at(-1)
                |> String.replace('.fy', '')

            lexer_and_parse_file_content_in_python(module_name, full_path)
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

    json = System.cmd("python3.6", ["-c", command]) |> elem(0) |> Jason.decode() |> elem(1)

    # 2º Convert each node from json to Fython format
    ParserNode.convert(json)
