import IO

import File

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
            i
                |> read_file_content()
                |> lexer_and_parse_file_content_in_python()
        )
        |> IO.inspect()


def lexer_and_parse_file_content_in_python(file_content):
    JSON.parse(file_content)
