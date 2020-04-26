def add_node(state, node):
    case node:
        None -> raise "add node received None"
        _ ->
            nodes = Map.get(state, 'nodes')
            Map.put(
                state, 'nodes', List.flatten([nodes, node])
            )

def has_error(state):
    Map.get(state, "error") != None

def tok_matchs(tok, type):
    Map.get(tok, "type") == type

def tok_matchs(tok, type, value):
    Map.get(tok, "type") == type and Map.get(tok, "value") == value

def get_next_tok(state):
    idx = state |> Map.get("current_tok_idx")
    tokens = state |> Map.get("tokens")
    idx = idx + 1
    tokens |> Enum.at(idx)

def set_error(state, msg, pos_start, pos_end):
    case Map.get(state, 'error'):
        None ->
            state = Map.put(
                state, "error", {"msg": msg, "pos_start": pos_start, pos_end: "pos_end"}
            )
            IO.inspect(state)
            state
        _ -> state