def run(project_full_path):
    project_name =
        project_full_path
        |> String.split("/")
        |> Enum.at(-1)


