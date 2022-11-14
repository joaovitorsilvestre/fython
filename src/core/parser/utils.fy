def has_error(state):
    Elixir.Map.get(state, "error") != None

def tok_matchs(tok, type):
    Elixir.Map.get(tok, "type") == type

def tok_matchs(tok, type, value):
    Elixir.Map.get(tok, "type") == type and Elixir.Map.get(tok, "value") == value

def get_next_tok(state):
    idx = state |> Elixir.Map.get("current_tok_idx")
    tokens = state |> Elixir.Map.get("tokens")
    idx = idx + 1
    tokens |> Elixir.Enum.at(idx)

def set_error(state, msg, pos_start, pos_end):
    case Elixir.Map.get(state, 'error'):
        None ->
            state = Elixir.Map.put(
                state, "error", {"msg": msg, "pos_start": pos_start, "pos_end": pos_end}
            )
            state
        _ -> state

def nodes_types():
    [
        :number,
        :atom,
        :var,
        :string,
        :unary,
        :list,
        :tuple,
        :binop,
        :pattern,
        :if,
        :func,
        :statements,
        :lambda,
        :def,
        :static_access,
        :raise,
        :assert,
        :pipe,
        :map,
        :case,
        :call,
        :try,
        :range,
        :protocol,
        :protocol_fn
    ]