import IO

import System

import File

import Conversorpython

def read_file_content(file_full_path):
    file_full_path
        |> File.read()
        |> elem(1)


def get_all_fy_files_in_path(directory_path):
    # return a list with full path of all .fy files in given directory
    # haha we dont have support for concatenate string or fstring

    [directory_path, "*.fy"]
        |> Enum.join("/")
        |> Path.wildcard()
        |> Enum.map(lambda i:
            module_name = i |> String.replace(directory_path) |> Enum.at(1)
            lexer_and_parse_file_content_in_python(module_name, i)
        )
        |> IO.inspect()


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
    Conversorpython.convert(json) |> IO.inspect()
