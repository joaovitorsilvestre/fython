def execute(state):
    case Elixir.Map.get(state, 'error'):
        None ->
            node = state
                |> Elixir.Map.get('node')
                |> Fcore.Parser.Pos.Localcalls.convert_local_function_calls([])

            Elixir.Map.put(state, 'node', node)
        _ -> state
