def print_cc(state):
    cc = Map.get(state, "current_tok")
    IO.puts(Enum.join([
        "CC: ", Map.get(cc, "type"), ", value: ", Map.get(cc, 'value') if Map.get(cc, 'value') != None else Map.get(cc, 'value')
    ]))

def execute(tokens):
    state = {
        "error": None,
        "current_tok_idx": 0,
        "current_tok": Enum.at(tokens, 0),
        "tokens": tokens |> Enum.filter(lambda i: Map.get(i, "type") != 'NEWLINE')
    }

    state |> parse()

def position(idx, ln, col):
    {"idx": idx, "ln": ln, "col": col}

def advance(state):
    idx = state |> Map.get("current_tok_idx")
    tokens = state |> Map.get("tokens")

    idx = idx + 1
    current_tok = tokens |> Enum.at(idx, None)

    new_state = {"current_tok": current_tok, "current_tok_idx": idx}

    Map.merge(state, new_state)


def loop_while(st, while_func, do_func):
    ct = Map.get(st, "current_tok")

    valid = while_func(ct)

    case valid:
        True ->
            do_func(st, ct) |> advance() |> loop_while(while_func, do_func)
        False -> st

def parse(state):
    state = expr(state)
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
            state

def factor(state):
    ct = Map.get(state, "current_tok")
    ct_type = ct |> Map.get('type')

    IO.puts('factor')
    print_cc(state)

    value = case:
        ct_type in ['PLUS', 'MINUS'] ->
            state = advance(state) |> factor()
            _factor = state |> Map.get("nodes") |> Enum.at(-1)
            node = Core.Parser.Nodes.make_unary_node(ct, _factor)
            state |> Core.Parser.Utils.add_node(node) |> advance()
        ct_type in ['INT', 'FLOAT'] ->
            state = advance(state)
            node = Core.Parser.Nodes.make_number_node(ct)
            state |> Core.Parser.Utils.add_node(node)
        True ->
            Core.Parser.Utils.set_error(
                state,
                "Expected int or float",
                Map.get(ct, "pos_start"),
                Map.get(ct, "pos_end")
            )

    value

def term(state):
    bin_op(state, &factor/1, ["MUL", 'DIV'])

def expr(state):
    bin_op(state, &term/1, ["MINUS", 'PLUS'])

def bin_op(state, func, ops):
    first_left = func(state) |> Map.get("nodes") |> Enum.at(-1)

    state = advance(state)

    state = loop_while(
        state,
        lambda ct:
            Enum.member?(ops, Map.get(ct, "type") if ct != None else None)
        ,
        lambda st, ct:
            left = Map.get(st, "_node", first_left)

            op_tok = Map.get(st, "current_tok")
            st = advance(st)

            right = func(st) |> Map.get("nodes") |> Enum.at(-1)

            Map.put(st, "_node", Core.Parser.Nodes.make_bin_op_node(left, op_tok, right))
    )

    case:
        Map.get(state, 'error') != None -> state
        True ->
            node = Map.get(state, '_node', first_left)
            state = Map.delete(state, '_node')

            case node:
                None -> state
                _ -> state |> Core.Parser.Utils.add_node(node)
