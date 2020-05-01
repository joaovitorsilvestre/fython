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
    p_result = statements(state)

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

def statements(state):
    statements(state, None)

def statements(state, only_ident_gte):
    expected_ident = case only_ident_gte:
        None -> Map.get(state, "current_tok") |> Map.get("ident")
        _ -> only_ident_gte

    pos_start = Map.get(state, "current_tok") |> Map.get("pos_start")

    p_result = statement(state)
    state = Enum.at(p_result, 0)
    first_statement = Enum.at(p_result, 1)

    state = loop_while(
        state,
        lambda state, ct:
            Map.get(state, "_break") != True
        ,
        lambda state, ct:
            _statements = Map.get(state, "_statements", [])
            ct_type = Map.get(ct, "type")

            more_statements = Map.get(ct, "ident") >= expected_ident

            more_statements = False if ct_type == "RPAREN" else more_statements

            case:
                not more_statements or ct_type == "EOF" -> Map.put(state, "_break", True)
                True ->
                    p_result = statement(state)
                    state = Enum.at(p_result, 0)
                    _statement = Enum.at(p_result, 1)

                    case _statement:
                        None -> Map.put(state, "_break", True)
                        _ -> Map.put(state, "_statements", List.flatten([_statements, _statement]))
    )

    _statements = Map.get(state, "_statements", [])
    _statements = List.flatten([first_statement, _statements])

    case:
        Map.get(state, "error") != None -> [state, None]
        _statements == [] ->
            ct = Map.get(state, "current_tok")

            state = Core.Parser.Utils.set_error(
                state,
                "Empty staments are not allowed",
                Map.get(ct, "pos_start"),
                Map.get(ct, "pos_end")
            )
            [state, None]
        True ->
            pos_end = Map.get(state, "current_tok") |> Map.get("pos_end")
            node = Core.Parser.Nodes.make_statements_node(_statements, pos_start, pos_end)

            state = state |> Map.delete("_statements") |> Map.delete("_break")

            [state, node]


def statement(state):
    p_result = expr(state)

    state = Enum.at(p_result, 0)
    _expr = Enum.at(p_result, 1)

    case Map.get(state, "error"):
        None -> [state, _expr]
        _ ->
            ct = Map.get(state, "current_tok")

            state = Core.Parser.Utils.set_error(
                state,
                "Expected int, float, variable, 'not', '+', '-', '(' or '['",
                Map.get(ct, "pos_start"),
                Map.get(ct, "pos_end")
            )
            [state, None]

def expr(state):
    ct = state |> Map.get('current_tok')
    ct_type = ct |> Map.get('type')

    next_tok_type = advance(state) |> Map.get('current_tok') |> Map.get('type')

    case:
        ct_type == 'IDENTIFIER' and next_tok_type == 'EQ' ->
            var_name = ct
            state = advance(state) |> advance()

            p_result = expr(state)
            state = Enum.at(p_result, 0)
            _expr = Enum.at(p_result, 1)

            case _expr:
                None ->
                    [state, None]
                _ ->
                    node = Core.Parser.Nodes.make_varassign_node(var_name, _expr)
                    [state, node]
        True ->
            _and = ["KEYWORD", "and"]
            _or = ["KEYWORD", "or"]

            p_result = bin_op(state, &comp_expr/1, [_and, _or], None)
            state = Enum.at(p_result, 0)
            node = Enum.at(p_result, 1)

            ct = Map.get(state, "current_tok")

            case:
                Core.Parser.Utils.tok_matchs(ct, 'KEYWORD', 'if') ->
                    if_expr(state, node)
                Map.get(ct, 'type') == 'PIPE' ->
                    pipe_expr(state, node)
                Core.Parser.Utils.tok_matchs(ct, 'KEYWORD', 'in') ->
                    state = advance(state)

                    p_result = expr(state)
                    state = Enum.at(p_result, 0)
                    right_node = Enum.at(p_result, 1)

                    node = Core.Parser.Nodes.make_in_node(
                        node, right_node
                    )
                    [state, node]
                True -> [state, node]


def comp_expr(state):
    ct = Map.get(state, "current_tok")

    case Core.Parser.Utils.tok_matchs(ct, "KEYWORD", 'not'):
        True ->
            state = advance(state)

            p_result = comp_expr(state)
            state = Enum.at(p_result, 0)
            c_node = Enum.at(p_result, 1)

            node = Core.Parser.Nodes.make_unary_node(ct, c_node)

            [state, node]
        False ->
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
            [state |> advance(), node]
        ct_type == 'STRING' ->
            node = Core.Parser.Nodes.make_string_node(ct)
            [state |> advance(), node]
        ct_type == 'IDENTIFIER' ->
            node = Core.Parser.Nodes.make_varaccess_node(ct)
            [state |> advance(), node]
        ct_type == 'ATOM' ->
            node = Core.Parser.Nodes.make_atom_node(ct)
            [state |> advance(), node]
        ct_type == 'ECOM' ->
            func_as_var_expr(state)
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
        ct_type == 'LSQUARE' -> list_expr(state)
        ct_type == 'LCURLY' -> map_expr(state)
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
        lambda state, ct:
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

def list_expr(state):
    pos_start = Map.get(state, "current_tok") |> Map.get("pos_start")

    state = loop_while(
        state,
        lambda state, ct:
            case:
                Map.get(ct, "type") == "RSQUARE" -> False
                Map.get(ct, "type") == "EOF" -> False
                Map.get(ct, "error") != None -> False
                True -> True
        ,
        lambda state, ct:
            element_nodes = Map.get(state, "_element_nodes", [])

            state = state if Map.get(ct, "type") == "COMMA" and element_nodes == [] else advance(state)

            case Map.get(state, "current_tok") |> Map.get("type"):
                "RSQUARE" -> state
                _ ->
                    p_result = expr(state |> Map.delete("_element_nodes"))
                    state = p_result |> Enum.at(0) |> Map.put("_element_nodes", element_nodes)
                    _expr = p_result |> Enum.at(1)

                    Map.put(
                        state,
                        "_element_nodes",
                        List.flatten([element_nodes, _expr])
                    )
    )

    ct = Map.get(state, "current_tok")

    case Map.get(ct, 'type'):
        'RSQUARE' ->
            element_nodes = Map.get(state, "_element_nodes", [])

            pos_end = Map.get(state, "current_tok") |> Map.get("pos_end")

            node = Core.Parser.Nodes.make_list_node(element_nodes, pos_start, pos_end)

            state = advance(state) |> Map.delete("_element_nodes")

            [state, node]
        _ ->
            state = Core.Parser.Utils.set_error(
                state,
                "Expected ']'",
                Map.get(ct, "pos_start"),
                Map.get(ct, "pos_end")
            )
            [state, None]


def map_expr(state):
    pos_start = Map.get(state, "current_tok") |> Map.get("pos_start")

    map_get_pairs = lambda (state):
        p_result = expr(state)
        state = p_result |> Enum.at(0)
        key = p_result |> Enum.at(1)

        case:
            (Map.get(state, "current_tok") |> Map.get("type")) == "DO" ->
                state = advance(state)

                p_result = expr(state)
                state = p_result |> Enum.at(0)
                value = p_result |> Enum.at(1)

                [state, {key: value}]
            True ->
                ct = Map.get(state, "current_tok")
                Core.Parser.Utils.set_error(
                    state,
                    "Empty staments are not allowed",
                    Map.get(ct, "pos_start"),
                    Map.get(ct, "pos_end")
                )
                [state, None]

    state = loop_while(
        state,
        lambda state, ct:
            case:
                Map.get(ct, "type") == "RCURLY" -> False
                Map.get(ct, "type") == "EOF" -> False
                Map.get(ct, "error") != None -> False
                True -> True
        ,
        lambda state, ct:
            pairs = Map.get(state, "_pairs", {})

            state = advance(state |> Map.delete("_pairs"))

            case Map.get(state, "current_tok") |> Map.get("type"):
                "RCURLY" -> state
                _ ->
                    p_result = map_get_pairs(state)
                    state = Enum.at(p_result, 0)
                    map = Enum.at(p_result, 1)

                    case map:
                        None -> state
                        _ -> Map.put(state, "_pairs", Map.merge(pairs, map))
    )

    ct = Map.get(state, "current_tok")

    case Map.get(ct, 'type'):
        'RCURLY' ->
            pairs = Map.get(state, "_pairs", {})
                |> Map.to_list()
                |> Enum.map(lambda i: [elem(i, 0), elem(i, 1)])

            pos_end = Map.get(state, "current_tok") |> Map.get("pos_end")

            node = Core.Parser.Nodes.make_map_node(pairs, pos_start, pos_end)

            state = advance(state) |> Map.delete("_pairs") |> Map.delete("_break")

            [state, node]
        _ ->
            state = Core.Parser.Utils.set_error(
                state,
                "Expected '}'",
                Map.get(ct, "pos_start"),
                Map.get(ct, "pos_end")
            )
            [state, None]

def if_expr(state, expr_for_true):
    state = advance(state)

    p_result = expr(state)
    state = Enum.at(p_result, 0)
    condition = Enum.at(p_result, 1)

    IO.inspect(Map.get(state, "current_tok"))

    case Core.Parser.Utils.tok_matchs(Map.get(state, "current_tok"), "KEYWORD", "else"):
        True ->
            state = advance(state)

            p_result = expr(state)
            state = Enum.at(p_result, 0)
            expr_for_false = Enum.at(p_result, 1)

            node = Core.Parser.Nodes.make_if_node(
                condition, expr_for_true, expr_for_false
            )
            [state, node]
        False ->
            state = Core.Parser.Utils.set_error(
                state,
                "Expected 'else'",
                Map.get(Map.get(state, "current_tok"), "pos_start"),
                Map.get(Map.get(state, "current_tok"), "pos_end")
            )

            [state, None]


def pipe_expr(state, left_node):
    state = advance(state)

    p_result = expr(state)
    state = Enum.at(p_result, 0)
    right_node = Enum.at(p_result, 1)

    case Map.get(state, 'error'):
        None ->
            node = Core.Parser.Nodes.make_pipe_node(left_node, right_node)
            [state, node]
        _ ->
            state = Core.Parser.Utils.set_error(
                state,
                "Expected and expression after '|>'",
                Map.get(Map.get(state, "current_tok"), "pos_start"),
                Map.get(Map.get(state, "current_tok"), "pos_end")
            )

            [state, None]

def func_as_var_expr(state):
    pos_start = Map.get(state, 'current_tok') |> Map.get('pos_start')
    state = advance(state)

    sequence = [
        state |> Map.get('current_tok') |> Map.get('type'),
        state |> advance() |> Map.get('current_tok') |> Map.get('type'),
        state |> advance() |> advance() |> Map.get('current_tok') |> Map.get('type')
    ]

    case sequence:
        ["IDENTIFIER", "DIV", "INT"] ->
            var_name_tok = Map.get(state, 'current_tok')

            state = advance(state)
            state = advance(state)

            arity = Map.get(state, 'current_tok')
            state = advance(state)

            node = Core.Parser.Nodes.make_funcasvariable_node(
                var_name_tok, arity, pos_start
            )
            [state, node]
        ['IDENTIFIER', _, "INT"] ->
            state = state |> advance()
            state = Core.Parser.Utils.set_error(
                state,
                "Expected '/'",
                Map.get(Map.get(state, "current_tok"), "pos_start"),
                Map.get(Map.get(state, "current_tok"), "pos_end")
            )
            [state, None]
        ['IDENTIFIER', "DIV", _] ->
            state = state |> advance() |> advance()
            state = Core.Parser.Utils.set_error(
                state,
                "Expected arity number as int",
                Map.get(Map.get(state, "current_tok"), "pos_start"),
                Map.get(Map.get(state, "current_tok"), "pos_end")
            )
            [state, None]
        [_, _, _] ->
            state = Core.Parser.Utils.set_error(
                state,
                "Expected the function name and arity. E.g: &sum/2",
                Map.get(Map.get(state, "current_tok"), "pos_start"),
                Map.get(Map.get(state, "current_tok"), "pos_end")
            )
            [state, None]