def execute(state, config):
    env = Elixir.Map.get(config, "env", [])

    var_names_avaliable = env
        |> Elixir.Enum.map(lambda ((var_name, _), obj):
            Elixir.Atom.to_string(var_name)
        )

    state_error = Elixir.Map.get(state, 'error')
    skip_pos_parser = Elixir.Map.get(config, "skip_pos_parser", False)

    case [state_error, skip_pos_parser]:
        [None, False] ->
            node = state
                |> Elixir.Map.get('node')
                |> Core.Parser.Pos.Localcalls.convert_local_function_calls(var_names_avaliable)
                |> Core.Parser.Pos.Nodesrefs.run(config)

            Elixir.Map.put(state, 'node', node)
        _ -> state
