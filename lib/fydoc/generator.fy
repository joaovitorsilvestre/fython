def gererate_docs(module_n_functions, project_path):
    module_n_functions
        |> Enum.map(lambda x: generate_doc(x, project_path))


def generate_doc((module_name, functions), project_path):
    sumary = functions
        |> Enum.with_index()
        |> Enum.map(lambda (func, index):
            Enum.join([
                '<a href="#func', index, '" class="function-sumary-header">',
                func,
                '</a>'
            ])
        )

    functions = functions
        |> Enum.with_index()
        |> Enum.map(lambda (func, index):
            Enum.join([
                '<h3 class="function-header" id="func', index,'">',
                func,
                '</h3>'
            ])
        )

    splited_module_name = module_name |> Elixir.String.split('.')

    file_content = Enum.join([
        Enum.join(["## ", module_name]),
        "### Sumary",
        *sumary,
        "### Functions",
        *functions
    ], "\n\n")

    result_file_name_with_path = generate_file_path(module_name, project_path)
    Elixir.File.mkdir_p!(result_file_name_with_path |> Elixir.Path.dirname())

    Elixir.File.write(result_file_name_with_path, file_content)


def generate_file_path(module_name, project_path):
    # returns docs/MyModule/ChildModule.md
    Enum.join([
        project_path |> Elixir.String.replace_trailing("/", ""),
        "/docs/modules/",
        module_name |> Elixir.String.split('.') |> Enum.join('/'),
        ".md"
    ])
