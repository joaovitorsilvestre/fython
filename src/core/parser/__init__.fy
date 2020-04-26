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
    current_tok = tokens |> Enum.at(idx)

    new_state = {"current_tok": current_tok}

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

def statements(state):
    statements(state, None)

def statements(state, only_ident_gte):
    pos_start = Map.get(state, "position")
    ct = Map.get(state, "current_tok")

    state = Core.Parser.Utils.skip_new_line_tok(state)

    expected_ident = only_ident_gte or Map.get(ct, 'ident')

    first_st = statement(state)

    case Core.Parser.Utils.has_error(state):
        True -> state
        False -> state

def statement(state):
    pos_start = Map.get(state, "position")
    ct = Map.get(state, "current_tok")

    state = Core.Parser.Utils.skip_new_line_tok(state)

    # TODO treat the cases

    _expr = expr(state)

    state


def expr(state):
    pos_start = Map.get(state, "position")
    ct = Map.get(state, "current_tok")

    next_token = Core.Parser.Utils.get_next_tok(state)

    # TODO treat the cases

    node = bin_op(&comp_expr/0, [[TT_KEYWORD, "and"], [TT_KEYWORD, "or"]])

    # TODO treat the cases

    Core.Parser.Utils.set_error(state, )





































