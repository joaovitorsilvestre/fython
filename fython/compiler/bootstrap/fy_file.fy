import IO

import File

def read_file_content(file_full_path):
    file_full_path
        |> File.read()
        |> elem(1)


def get_all_fy_files_in_path(directory_path):
    # return a list with full path of all .fy files in given directory
    # haha we dont have support for concatenate strinf or fstring

    [directory_path, "*.fy"]
        |> Enum.join("/")
        |> Path.wildcard()

