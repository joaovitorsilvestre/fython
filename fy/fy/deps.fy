def get_deps_of_project(project_path):
    (:ok, content) = Elixir.File.read(Elixir.Enum.join([project_path, "/requirements.txt"]))

    content
        |> Elixir.String.split('\n')
        |> Elixir.Enum.filter(lambda i: i != "")
        |> Elixir.Enum.map(lambda i:
            [module_name, url] = Elixir.String.split(i, '=')
            (module_name, url)
        )

def install_deps(deps, project_path):
    deps
        |> Elixir.Enum.map(lambda i:
            (dep_name, url) = i

            Fy.Core.install_package_from_url(project_path, dep_name, url)
        )