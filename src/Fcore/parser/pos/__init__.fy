def execute(state):
    case Map.get(state, 'error'):
        None ->
            node = state
                |> Map.get('node')
                |> Fcore.Parser.Pos.Localcalls.convert_local_function_calls([])

            Map.put(state, 'node', node)
        _ -> state
