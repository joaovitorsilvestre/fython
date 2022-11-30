def run(project_path):
    project_path
        |> Fydoc.Scanner.get_functions_defs()
        |> Fydoc.Generator.gererate_docs(project_path)
