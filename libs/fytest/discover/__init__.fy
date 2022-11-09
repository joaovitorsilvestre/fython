def get_module_name_of_path(path):
    path
        |> Elixir.String.replace_suffix('/', '')
        |> Elixir.String.split('/')
        |> Elixir.Enum.at(-1)
        |> Elixir.Macro.camelize()

def find_test_functions(test_module):
    modules = get_modules(test_module)

    modules
        |> Elixir.Enum.map(
            lambda module:
                functions = module |> get_tests_of_module()
                (module, functions)
        )

def get_tests_of_module(module):
    module
        |> get_functions_of_module()
        |> Elixir.Enum.filter(lambda (func_name, _arity):
            func_name
                |> Elixir.Atom.to_string()
                |> Elixir.String.starts_with?("test_")
        )

def get_functions_of_module(module):
    # get_functions_of_module(:"Fython.Shell")
    # TODO go to core
    Elixir.Kernel.apply(module, :__info__, [:functions])

def get_modules(path):
    [path, "**/*.fy"]
        |> Elixir.Enum.join('/')
        |> Elixir.Path.wildcard()
        |> Elixir.Enum.map(lambda file_full_path:
            module_name = Core.Code.get_module_name(path, file_full_path)
            (:module, module) = Elixir.Code.ensure_loaded(Elixir.String.to_atom(module_name))
            module
        )
