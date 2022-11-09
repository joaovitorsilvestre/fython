def compile_project(project_path):
    Core.Generator.Compiler.compile_project(project_path)

def install(project_path):
    project_path
        |> Fy.Deps.get_deps_of_project()
        |> Fy.Deps.install_deps(project_path)

