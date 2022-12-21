def topology_sort(info <- {"data": data, "result": result}):
    ordered = data
        |> Elixir.Map.to_list()
        |> Elixir.Enum.filter(lambda (item, deps): deps == Elixir.MapSet.new())
        |> Elixir.Enum.map(lambda (item, deps): item)
        |> Elixir.MapSet.new()

    case ordered == Elixir.MapSet.new():
        True -> info
        False ->
            data = data
                |> Elixir.Map.to_list()
                |> Elixir.Enum.filter(lambda (item, deps): not Elixir.MapSet.member?(ordered, item))
                |> Elixir.Enum.map(lambda (item, deps): (item, Elixir.MapSet.difference(deps, ordered)))
                |> Elixir.Map.new()

            topology_sort({"result": [*result, *ordered], "data": data})


def topology_sort(data):
    # Input
    #    {
    #        'parser': ['lexer', 'kernel'],
    #        'lexer': ['kernel']
    #    }
    # Output ['kernel', 'lexer', 'parser']

    data = data
        |> Elixir.Map.to_list()
        |> Elixir.Enum.map(lambda (item, deps):
            # Ignore self dependencies
            deps = Elixir.MapSet.difference(
                Elixir.MapSet.new(deps),
                Elixir.MapSet.new([item])
            )
            (item, deps)
        )
        |> Elixir.Map.new()

    extra_items_in_deps = data
        |> Elixir.Map.values()
        |> Elixir.Enum.reduce(lambda acc, deps:
            Elixir.MapSet.union(acc, deps)
        )
        |> Elixir.MapSet.difference(Elixir.MapSet.new(Elixir.Map.keys(data)))

    data = extra_items_in_deps
        |> Elixir.Enum.map(lambda item: (item, Elixir.MapSet.new()))
        |> Elixir.Map.new()
        |> Elixir.Map.merge(data)

    result = topology_sort({"data": data, "result": []})

    case result['data']:
        {} -> result['result']
        _ -> raise "A cyclic dependency exists amongst" # TODO improve feedback of what the cyclic dependency is

def sort_modules_by_dependencies(modules):
    # modules: [(file, module_name, elixir_ast, dependencies)]
    #    parent_module: (module_name, elixir_ast)
    #    child_modules: [(module_name, elixir_ast), ...]

    # It will become a map of priority of each module
    # {
    #     'ModuleA': 0,
    #     'ModuleB': 1,
    #}
    modules_names_ordered_by_dps = modules
        |> Elixir.Enum.map(lambda (_file, module_name, _elixir_ast, deps):
            (module_name, deps)
        )
        |> Elixir.Map.new()
        |> topology_sort()
        |> Elixir.Enum.with_index()
        |> Elixir.Map.new()

    modules
        |> Elixir.Enum.sort_by(lambda (_, m_name, _, _):
            modules_names_ordered_by_dps[m_name]
        )


def is_a_module_ref?(name):
    # Returns true if it's a valid module name, including if has a function
    #     Module -> True
    #     Module.SubModule -> True
    #     Module.SubModule.function -> True
    #     ExceptionError -> True
    #     module -> False
    #     _MyModule -> False
    first_letter = name |> Elixir.String.at(0)
    is_letter = Elixir.String.contains?(Core.Lexer.Consts.letters(), first_letter)
    same_as_uppercase = first_letter == Elixir.String.upcase(first_letter)

    case:
        first_letter == '_' -> False
        is_letter and same_as_uppercase -> True
        True -> False

def only_module_name(name):
    # Removes the function from the name of the module
    # e.g Module.SubModule.function -> Module.SubModule
    name
        |> Elixir.String.split('.')
        |> Elixir.Enum.filter(lambda x:
            first_letter = Elixir.String.at(x, 0)
            first_letter == Elixir.String.upcase(first_letter)
        )
        |> Elixir.Enum.join('.')

def find_dependencies_of_module(node):
    [node, state] = Core.Parser.Traverse.run(node, {
        "dependencies": []
    }, &find_dep/2)

    state["dependencies"]


def find_dep(node <- (:var, _, [_pinned, "True"]), state):
    [node, state]

def find_dep(node <- (:var, _, [_pinned, "False"]), state):
    [node, state]

def find_dep(node <- (:var, _, [_pinned, "None"]), state):
    [node, state]

def find_dep(node <- (:var, meta, [_pinned, name]), state):
    is_module = is_a_module_ref?(name)
    elixir_module = (
        (Elixir.String.starts_with?(name, "Elixir.") or Elixir.String.starts_with?(name, "Erlang."))
        and not Elixir.String.starts_with?(name, "Elixir.Fython.")
    )

    state = case is_module and not elixir_module:
        True ->
            name = only_module_name(name)
            Elixir.Map.put(state, "dependencies", [*state['dependencies'], name])
        False -> state

    [node, state]

def find_dep(node, state):
    [node, state]