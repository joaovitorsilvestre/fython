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

def get_modules_sorted_by_dependencies(dependencies):
    topology_sort(dependencies)