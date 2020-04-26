def execute(tokens):
    state = {
        "error": None,
        "current_tok": None,
        "next_tok": None,
        "_current_tok_idx": -1,
        "_tokens": tokens |> Enum.filter(lambda i: Map.get(i, "type") != 'NEWLINE')
    }

    state |> advance() |> parse()

def advance(state):
    idx = state |> Map.get("_current_tok_idx")
    tokens = state |> Map.get("_tokens")

    idx = idx + 1
    current_tok = tokens |> Enum.at(idx, None)

    new_state = {
        "current_tok": current_tok,
        "prev_tok": Enum.at(tokens, idx - 1, None),
        "next_tok": Enum.at(tokens, idx + 1, None),
        "_current_tok_idx": idx,
    }

    Map.merge(state, new_state)

def parse(state):
    p_result = expr(state)

    state = p_result |> Enum.at(0)
    node = p_result |> Enum.at(1)

    ct = Map.get(state, "current_tok")

    case Map.get(state, "error") != None and Map.get(ct, "type") != "EOF":
        True ->
            Core.Parser.Utils.set_error(
                state,
                "Expected '+' or '-' or '*' or '/'",
                Map.get(ct, "pos_start"),
                Map.get(ct, "pos_end")
            )
        False ->
            Map.merge(state, {"node": node})

def expr(state):
    bin_op(state, &term/1, ["MINUS", 'PLUS'], None)

def term(state):
    bin_op(state, &factor/1, ["MUL", 'DIV'], None)

def power(state):
    bin_op(state, &call/1, ["POW"], &call/1)

def call(state):
    # TODO treat parenteses
    state |> atom()

def factor(state):
    ct = Map.get(state, "current_tok")
    ct_type = ct |> Map.get('type')

    case ct_type in ['PLUS', 'MINUS']:
        True ->
            state = state |> advance()

            p_result = factor(state)
            state = p_result |> Enum.at(0)
            _factor = p_result |> Enum.at(1)

            case Map.get(state, "error"):
                None ->
                    node = Core.Parser.Nodes.make_unary_node(ct, _factor)
                    [state, node]
                _ -> [state, None]

        False -> power(state)

def atom(state):
    ct = Map.get(state, "current_tok")
    ct_type = ct |> Map.get('type')

    case:
        ct_type in ['INT', 'FLOAT'] ->
            node = Core.Parser.Nodes.make_number_node(ct)
            state = state |> advance()
            [state, node]
        True ->
            state = Core.Parser.Utils.set_error(
                state,
                Enum.join([
                    "Expected int, float, identifier, '+', '-', '(', '[', if, def, lambda or case. ",
                    "Received: ",
                    ct_type
                ]),
                Map.get(ct, "pos_start"),
                Map.get(ct, "pos_end")
            )
            [state, None]


def bin_op(state, func_a, ops, func_b):
    func_b = func_b if func_b != None else func_a

    p_result = func_a(state)
    state = p_result |> Enum.at(0)
    left = p_result |> Enum.at(1)

    ct = Map.get(state, "current_tok")

    # todo add later the OR op here, it will enable and & or to work too
    case ct != None and Map.get(ct, "type") in ops:
        True ->
            op_tok = ct

            p_result = state |> advance() |> func_b()
            state = p_result |> Enum.at(0)
            left = p_result |> Enum.at(1)

            case Map.get(state, "error"):
                None -> bin_op(state, func_a, ops, func_b)
                _ -> [state, None]
        False -> [state, left]
