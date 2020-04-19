import IO, System, File, ParserNode, Utils


def compile_project(project_path):
    # Compile project and save files into subfolder 'compiled'

    all_modules_compiled = compile_project_to_binary(project_path)

    File.mkdir_p!([project_path, "compiled"] |> Enum.join('/'))

    all_modules_compiled
        |> Enum.map(lambda modulename_n_coted:
            module_name = modulename_n_coted |> elem(0)
            compiled = modulename_n_coted |> elem(1)

            File.write(
                Utils.join_str([project_path, "/compiled/", module_name, ".beam"]), compiled, mode=:binary
            )
        )


def compile_project_to_binary(directory_path):
    # Return a list of each module compiled into elixir AST in binary
    # read to be evaluated in Elixir
    # Ex:
    # iex> Compiler.compile_project(ABSOLUTE_PATH_TO_PROJECT_FOLDER)
    # exit the shell
    # go to compiled folder and start iex again.
    # Now, you should be able to call any module of this project in iex

    [directory_path, "*.fy"]
        |> Enum.join('/')
        |> Path.wildcard()
        |> Enum.map(lambda full_path:
            module_name = full_path
                |> String.split('/')
                |> Enum.at(-1)
                |> String.replace('.fy', '')
                |> String.capitalize()

            [
                module_name,
                lexer_and_parse_file_content_in_python(
                    module_name, full_path
                )
            ]
        )
        |> Enum.map(lambda modulename_n_content:
            module_name = modulename_n_content |> Enum.at(0)
            compiled = modulename_n_content |> Enum.at(1)

            module = Utils.join_str([
                "{:defmodule, [line: 1], ",
                "[{:__aliases__, [line: 1], [:", module_name, "]}, ",
                "[do: ", compiled, "]]}"
            ])

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

    # 2º Convert each node from json to Fython format
    ParserNode.convert(json)
