def execute(state, env):
    var_names_avaliable = env
        |> Elixir.Enum.map(lambda ((var_name, _), obj):
            Elixir.Atom.to_string(var_name)
        )

    case Elixir.Map.get(state, 'error'):
        None ->
            node = state
                |> Elixir.Map.get('node')
                |> Core.Parser.Pos.Localcalls.convert_local_function_calls(var_names_avaliable)
                |> Core.Parser.Pos.Statementsrefs.add_statements_refs()

            Elixir.Map.put(state, 'node', node)
        _ -> state
