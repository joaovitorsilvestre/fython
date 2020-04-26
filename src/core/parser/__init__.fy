def execute(tokens):
    state = {
        "error": None,
        "current_tok": Enum.at(tokens, 0),
        "tokens": tokens
    }

    state |> parse()

def position(idx, ln, col):
    {"idx": idx, "ln": ln, "col": col}

def advance(state):
    idx = state |> Map.get("position") |> Map.get("idx")
    tokens = state |> Map.get("tokens")

    idx = idx + 1
    current_char = tokens |> Enum.at(idx)

    new_state = {"current_tok": current_char}

    Map.merge(state, new_state)

def get_tok_type(token):
    token |> Map.get("type")

def parse(state):
    tokens = Map.get("tokens")

    case:
        get_tok_type(Enum.at(tokens, 0)) == "EOF" ->
            Core.Parser.Nodes.statements_node(tokens)
        _ ->
            statements(state)

def statements():
