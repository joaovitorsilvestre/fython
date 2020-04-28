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

    case idx >= Enum.count(tokens):
        True -> state
        False ->
            new_state = {
                "current_tok": current_tok,
                "prev_tok": Enum.at(tokens, idx - 1, None) if idx > 0 else None,
                "next_tok": Enum.at(tokens, idx + 1, None),
                "_current_tok_idx": idx,
            }

            Map.merge(state, new_state)

def parse(state):
    p_result = expr(state)

    state = p_result |> Enum.at(0)
    node = p_result |> Enum.at(1)

    ct = Map.get(state, "current_tok")

    case Map.get(state, "error") == None and Map.get(ct, "type") != "EOF":
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
    _and = ["KEYWORD", "and"]
    _or = ["KEYWORD", "or"]
    bin_op(state, &comp_expr/1, [_and, _or], None)

def comp_expr(state):
    # TODO treat not
    bin_op(state, &arith_expr/1, ["EE", "NE", "LT", "LTE", "GT", "GTE"], None)

def arith_expr(state):
    bin_op(state, &term/1, ["PLUS", "MINUS"], None)

def term(state):
    bin_op(state, &factor/1, ["MUL", 'DIV'], None)

def power(state):
    bin_op(state, &call/1, ["POW"], &call/1)

def call(state):
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
        ct_type == 'LPAREN' ->
            state = advance(state)

            p_result = expr(state)
            state = Enum.at(p_result, 0)
            _expr = Enum.at(p_result, 1)

            case:
                (Map.get(state, 'current_tok') |> Map.get('type')) == 'RPAREN' ->
                    state = advance(state)
                    [state, _expr]
                True ->
                    state = Core.Parser.Utils.set_error(
                        state, "Expected ')'", Map.get(ct, "pos_start"), Map.get(ct, "pos_end")
                    )
                    [state, None]
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


def loop_while(st, while_func, do_func):
    ct = Map.get(st, "current_tok")

    valid = while_func(st, ct)

    case valid:
        True -> do_func(st, ct) |> loop_while(while_func, do_func)
        False -> st

def bin_op(state, func_a, ops, func_b):
    func_b = func_b if func_b != None else func_a

    p_result = func_a(state)
    state = p_result |> Enum.at(0)
    left = p_result |> Enum.at(1)

    ct = Map.get(state, "current_tok")

    state = loop_while(
        state,
        lambda st, ct:
            Enum.member?(ops, Map.get(ct, "type")) or Enum.member?(ops, [Map.get(ct, "type"), Map.get(ct, "value")])
        ,
        lambda state, ct:
            left = Map.get(state, "_node", left)

            op_tok = Map.get(state, 'current_tok')
            state = advance(state)
            p_result = func_b(state)

            state = p_result |> Enum.at(0)
            right = p_result |> Enum.at(1)

            case Map.get(state, "error"):
                None ->
                    left = Core.Parser.Nodes.make_bin_op_node(left, op_tok, right)
                    Map.put(state, "_node", left)
                _ -> state
    )

    left = Map.get(state, '_node', left)
    state = Map.delete(state, '_node')

    [state, left]