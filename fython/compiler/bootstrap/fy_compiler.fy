def run(project_full_path):
    project_name = project_full_path |> Enum.slice("/") |> Enum.slice(-1)

