def loop_while(st, func):
    st = advance(st)
    ct = Map.get(st, "current_tok")
    result = Map.get(st, "result")

    valid = func(ct)

    case valid:
        True -> Map.put(st, "result", Enum.join([result, ct])) |> loop_while(func)
        False -> st

def has_error(state):
    Map.get(state, "error") != None

def tok_matchs(tok, type):
    Map.get(tok, "type") == type

def tok_matchs(tok, type, value):
    Map.get(tok, "type") == type and Map.get(tok, "value") == value

def skip_new_line_tok(state):
    loop_while(state, lambda ct:
        Map.get(ct, "type") == "NEW_LINE"
    )

def get_next_tok(state):
    idx = state |> Map.get("position") |> Map.get("idx")
    tokens = state |> Map.get("tokens")
    idx = idx + 1
    tokens |> Enum.at(idx)

def set_error(state):
