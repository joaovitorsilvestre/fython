def execute(state, config):
    env = Elixir.Map.get(config, "env", [])
    bootstrap_prefix = Elixir.Map.get(config, "bootstrap_prefix")

    var_names_avaliable = env
        |> Elixir.Enum.map(lambda ((var_name, _), obj):
            Elixir.Atom.to_string(var_name)
        )

    state_error = Elixir.Map.get(state, 'error')
    compiling_module = Elixir.Map.get(config, "compiling_module", False)

    case [state_error, compiling_module]:
        [None, True] ->
            node = state
                |> Elixir.Map.get('node')
                |> Core.Parser.Pos.Localcalls.convert_local_function_calls(var_names_avaliable)
                |> Core.Parser.Pos.Bootprefix.add_prefix_to_function_calls(bootstrap_prefix)
                |> Core.Parser.Pos.Exceptions.catch_and_convert_elixir_excetions_to_fython(bootstrap_prefix)

            Elixir.Map.put(state, 'node', node)
        _ -> state
