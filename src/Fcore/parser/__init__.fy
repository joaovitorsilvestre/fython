def execute(tokens):
    state = {
        "error": None,
        "prev_tok": None,
        "current_tok": None,
        "next_tok": None,
        "node": None,
        "_current_tok_idx": -1,
        "_tokens": tokens |> Enum.filter(lambda i: Map.get(i, "type") != 'NEWLINE')
    }

    state |> advance() |> parse() |> Fcore.Parser.Pos.execute()

def advance(state):
    # before anything, lets check that the states only contains expected keys
    # other wise they are invalid and can have terrible effects in recusive functions
    valid_keys = [
        "error", "current_tok", "next_tok",
        "node", "_current_tok_idx", "_tokens", "prev_tok"
    ]

    state_filtered = state
        |> Map.to_list()
        |> Enum.filter(lambda key_n_value: elem(key_n_value, 0) in valid_keys)
        |> Map.new()

    case state_filtered != state:
        True ->
            # If you get this error. Almost sure that some key
            # wasnt deleted in some loop_while lambdas
            raise "trying to advance state with invalid keys"
        False -> None

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
                "_current_tok_idx": idx
            }

            Map.merge(state, new_state)

def parse(state):
    [state, node] = statements(state)

    ct = Map.get(state, "current_tok")

    case Map.get(state, "error") == None and Map.get(ct, "type") != "EOF":
        True ->
            Fcore.Parser.Utils.set_error(
                state,
                "Expected '+' or '-' or '*' or '/'",
                Map.get(ct, "pos_start"),
                Map.get(ct, "pos_end")
            )
        False ->
            Map.merge(state, {"node": node})

def statements(state):
    statements(state, 0)

def statements(state, expected_ident_gte):
    pos_start = Map.get(state, "current_tok") |> Map.get("pos_start")

    state = loop_while(
        state,
        lambda state, ct:
            Map.get(state, "_break") != True
        ,
        lambda state, ct:
            _statements = Map.get(state, "_statements", [])
            state = Map.delete(state, '_statements')

            ct_type = Map.get(ct, "type")

            more_statements = Map.get(ct, "ident") >= expected_ident_gte

            more_statements = False if ct_type == "RPAREN" else more_statements

            case:
                not more_statements or ct_type == "EOF" ->
                    state
                        |> Map.put("_break", True)
                        |> Map.put("_statements", _statements)
                True ->
                    [state, _statement] = statement(state)

                    case _statement:
                        None ->
                            state
                                |> Map.put("_break", True)
                                |> Map.put("_statements", _statements)
                        _ ->
                            Map.put(
                                state,
                                "_statements",
                                List.insert_at(_statements, -1, _statement)
                            )
    )

    _statements = Map.get(state, "_statements", [])
    state = Map.delete(state, "_statements") |> Map.delete("_break")

    case:
        Map.get(state, "error") != None ->
            [state, None]
        _statements == [] ->
            ct = Map.get(state, "current_tok")

            state = Fcore.Parser.Utils.set_error(
                state,
                "Empty staments are not allowed",
                Map.get(ct, "pos_start"),
                Map.get(ct, "pos_end")
            )
            [state, None]
        True ->
            pos_end = Map.get(state, "current_tok") |> Map.get("pos_end")
            node = Fcore.Parser.Nodes.make_statements_node(_statements, pos_start, pos_end)

            [state, node]


def statement(state):
    ct = Map.get(state, 'current_tok')
    pos_start = Map.get(ct, 'pos_start')

    [state, node] = case:
        Fcore.Parser.Utils.tok_matchs(ct, 'KEYWORD', 'raise') ->
            pos_start = Map.get(ct, 'pos_start')

            [state, _expr] = state |> advance() |> expr()

            node = Fcore.Parser.Nodes.make_raise_node(_expr, pos_start)
            [state, node]
        True ->
            [state, _expr] = expr(state)

            case Map.get(state, "error"):
                None -> [state, _expr]
                _ ->
                    ct = Map.get(state, "current_tok")

                    state = Fcore.Parser.Utils.set_error(
                        state,
                        "Expected int, float, variable, 'not', '+', '-', '(' or '['",
                        Map.get(ct, "pos_start"),
                        Map.get(ct, "pos_end")
                    )
                    [state, None]

    case (Map.get(state, 'current_tok') |> Map.get('type')) == 'EQ':
        True -> pattern_match(state, node, pos_start)
        False -> [state, node]

def expr(state):
    ct = state |> Map.get('current_tok')
    ct_type = ct |> Map.get('type')

    _and = ["KEYWORD", "and"]
    _or = ["KEYWORD", "or"]

    [state, node] = bin_op(state, &comp_expr/1, [_and, _or], None)

    ct = Map.get(state, "current_tok")

    case:
        Fcore.Parser.Utils.tok_matchs(ct, 'KEYWORD', 'if') ->
            if_expr(state, node)
        Map.get(ct, 'type') == 'PIPE' ->
            pipe_expr(state, node)
        Fcore.Parser.Utils.tok_matchs(ct, 'KEYWORD', 'in') ->
            state = advance(state)

            [state, right_node] = expr(state)

            node = Fcore.Parser.Nodes.make_in_node(
                node, right_node
            )
            [state, node]
        True -> [state, node]


def comp_expr(state):
    ct = Map.get(state, "current_tok")

    case Fcore.Parser.Utils.tok_matchs(ct, "KEYWORD", 'not'):
        True ->
            state = advance(state)

            [state, c_node] = comp_expr(state)

            node = Fcore.Parser.Nodes.make_unary_node(ct, c_node)

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
    [state, _atom] = atom(state)

    prev_tok_ln = state
        |> Map.get('_tokens')
        |> Enum.at(Map.get(state, '_current_tok_idx') - 1)
        |> Map.get('pos_end')
        |> Map.get('ln')

    ct = Map.get(state, 'current_tok')
    ct_type = Map.get(ct, 'type')

    # we must only consider as a call node if the previous node is
    # in the same line that the left parent

    case ct_type == 'LPAREN' and (Map.get(ct, 'pos_start') |> Map.get('ln')) == prev_tok_ln:
        True -> call_func_expr(state, _atom)
        False -> [state, _atom]

def factor(state):
    ct = Map.get(state, "current_tok")
    ct_type = ct |> Map.get('type')

    case ct_type in ['PLUS', 'MINUS']:
        True ->
            state = state |> advance()

            [state, _factor] = factor(state)

            case Map.get(state, "error"):
                None ->
                    node = Fcore.Parser.Nodes.make_unary_node(ct, _factor)
                    [state, node]
                _ -> [state, None]

        False -> power(state)

def atom(state):
    ct = Map.get(state, "current_tok")
    ct_type = ct |> Map.get('type')

    pos_start = Map.get(ct, 'pos_start')

    case:
        ct_type in ['INT', 'FLOAT'] ->
            node = Fcore.Parser.Nodes.make_number_node(ct)
            [state |> advance(), node]
        ct_type == 'STRING' ->
            node = Fcore.Parser.Nodes.make_string_node(ct)
            [state |> advance(), node]
        ct_type == 'IDENTIFIER' or ct_type == 'PIN' ->
            is_pinned = ct_type == 'PIN'

            (state, ct) = (advance(state), Map.get(advance(state), 'current_tok')) if is_pinned else (state, ct)

            node = Fcore.Parser.Nodes.make_varaccess_node(ct, is_pinned)
            [state |> advance(), node]
        ct_type == 'ATOM' ->
            node = Fcore.Parser.Nodes.make_atom_node(ct)
            [state |> advance(), node]
        ct_type == 'ECOM' ->
            func_as_var_expr(state)
        ct_type == 'LPAREN' ->
            state = advance(state)

            [state, _expr] = case (Map.get(state, 'current_tok') |> Map.get('type')) == 'RPAREN':
                True -> [state, None]
                False -> expr(state)

            ct_type = Map.get(state, 'current_tok') |> Map.get('type')

            case:
                # if the _expr is None it means that we are defining
                # a tuple without elements. Eg: ()
                ct_type == 'COMMA' or _expr == None ->
                    tuple_expr(state, pos_start, _expr)
                ct_type == 'RPAREN' ->
                    state = advance(state)
                    [state, _expr]
                True ->
                    ct = Map.get(state, 'current_tok')

                    state = Fcore.Parser.Utils.set_error(
                        state, "Expected ')'", Map.get(ct, "pos_start"), Map.get(ct, "pos_end")
                    )
                    [state, None]
        ct_type == 'LSQUARE' -> list_expr(state)
        ct_type == 'LCURLY' -> map_expr(state)
        Fcore.Parser.Utils.tok_matchs(ct, "KEYWORD", "case") ->
            case_expr(state)
        Fcore.Parser.Utils.tok_matchs(ct, "KEYWORD", "def") ->
            func_def_expr(state)
        Fcore.Parser.Utils.tok_matchs(ct, "KEYWORD", "lambda") ->
            lambda_expr(state)
        True ->
            state = Fcore.Parser.Utils.set_error(
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

    [state, first_left] = func_a(state)

    ct = Map.get(state, "current_tok")

    state = loop_while(
        state,
        lambda state, ct:
            case:
                Map.get(ct, "type") == "EOF" -> False
                Map.get(state, "error") != None -> False
                Enum.member?(ops, Map.get(ct, "type")) or Enum.member?(ops, [Map.get(ct, "type"), Map.get(ct, "value")]) -> True
                True -> False
        ,
        lambda state, ct:
            left = Map.get(state, "_node", first_left)
            state = Map.delete(state, "_node")

            op_tok = Map.get(state, 'current_tok')
            state = advance(state)

            [state, right] = func_b(state)

            case Map.get(state, "error"):
                None ->
                    left = Fcore.Parser.Nodes.make_bin_op_node(left, op_tok, right)
                    Map.put(state, "_node", left)
                _ -> state
    )

    left = Map.get(state, '_node', first_left)
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
                Map.get(state, "error") != None -> False
                True -> True
        ,
        lambda state, ct:
            element_nodes = Map.get(state, "_element_nodes", [])
            state = Map.delete(state, "_element_nodes")

            state = state if Map.get(ct, "type") == "COMMA" and element_nodes == [] else advance(state)

            case Map.get(state, "current_tok") |> Map.get("type"):
                "RSQUARE" -> state
                _ ->
                    [state, _expr] = expr(state)

                    Map.put(
                        state |> Map.put("_element_nodes", element_nodes),
                        "_element_nodes",
                        List.flatten([element_nodes, _expr])
                    )
    )

    ct = Map.get(state, "current_tok")

    case Map.get(ct, 'type'):
        'RSQUARE' ->
            element_nodes = Map.get(state, "_element_nodes", [])
            state = Map.delete(state, "_element_nodes")

            pos_end = Map.get(state, "current_tok") |> Map.get("pos_end")

            node = Fcore.Parser.Nodes.make_list_node(element_nodes, pos_start, pos_end)

            state = advance(state)

            [state, node]
        _ ->
            state = Fcore.Parser.Utils.set_error(
                state,
                "Expected ']'",
                Map.get(ct, "pos_start"),
                Map.get(ct, "pos_end")
            )
            [state, None]


def map_expr(state):
    pos_start = Map.get(state, "current_tok") |> Map.get("pos_start")

    map_get_pairs = lambda state:
        [state, key] = expr(state)

        case:
            (Map.get(state, "current_tok") |> Map.get("type")) == "DO" ->
                state = advance(state)

                [state, value] = expr(state)

                [state, {key: value}]
            True ->
                ct = Map.get(state, "current_tok")
                Fcore.Parser.Utils.set_error(
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
                Map.get(state, "error") != None -> False
                True -> True
        ,
        lambda state, ct:
            pairs = Map.get(state, "_pairs", {})
            state = Map.delete(state, "_pairs")

            state = advance(state)

            case Map.get(state, "current_tok") |> Map.get("type"):
                "RCURLY" -> state
                _ ->
                    [state, map] = map_get_pairs(state)

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

            node = Fcore.Parser.Nodes.make_map_node(pairs, pos_start, pos_end)

            state = state |> Map.delete("_pairs") |> Map.delete("_break") |> advance()

            [state, node]
        _ ->
            state = Fcore.Parser.Utils.set_error(
                state,
                "Expected '}'",
                Map.get(ct, "pos_start"),
                Map.get(ct, "pos_end")
            )
            [state, None]


def if_expr(state, expr_for_true):
    state = advance(state)

    [state, condition] = expr(state)

    case Fcore.Parser.Utils.tok_matchs(Map.get(state, "current_tok"), "KEYWORD", "else"):
        True ->
            state = advance(state)

            [state, expr_for_false] = expr(state)

            node = Fcore.Parser.Nodes.make_if_node(
                condition, expr_for_true, expr_for_false
            )
            [state, node]
        False ->
            state = Fcore.Parser.Utils.set_error(
                state,
                "Expected 'else'",
                Map.get(Map.get(state, "current_tok"), "pos_start"),
                Map.get(Map.get(state, "current_tok"), "pos_end")
            )

            [state, None]


def pipe_expr(state, left_node):
    state = advance(state)

    [state, right_node] = expr(state)

    case Map.get(state, 'error'):
        None ->
            node = Fcore.Parser.Nodes.make_pipe_node(left_node, right_node)
            [state, node]
        _ ->
            state = Fcore.Parser.Utils.set_error(
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

            node = Fcore.Parser.Nodes.make_funcasvariable_node(
                var_name_tok, arity, pos_start
            )
            [state, node]
        ['IDENTIFIER', _, "INT"] ->
            state = state |> advance()
            state = Fcore.Parser.Utils.set_error(
                state,
                "Expected '/'",
                Map.get(Map.get(state, "current_tok"), "pos_start"),
                Map.get(Map.get(state, "current_tok"), "pos_end")
            )
            [state, None]
        ['IDENTIFIER', "DIV", _] ->
            state = state |> advance() |> advance()
            state = Fcore.Parser.Utils.set_error(
                state,
                "Expected arity number as int",
                Map.get(Map.get(state, "current_tok"), "pos_start"),
                Map.get(Map.get(state, "current_tok"), "pos_end")
            )
            [state, None]
        [_, _, _] ->
            state = Fcore.Parser.Utils.set_error(
                state,
                "Expected the function name and arity. E.g: &sum/2",
                Map.get(Map.get(state, "current_tok"), "pos_start"),
                Map.get(Map.get(state, "current_tok"), "pos_end")
            )
            [state, None]


def case_expr(state):
    pos_start = Map.get(state, 'current_tok') |> Map.get('pos_start')
    initial_ident = Map.get(state, "current_tok") |> Map.get('ident')

    state = advance(state)

    is_cond = (Map.get(state, "current_tok") |> Map.get("type")) == "DO"

    [state, _expr] = case is_cond:
        True -> [state, None]
        False -> expr(state)

    do_line = pos_start |> Map.get('ln')
    state = advance(state)

    check_ident = lambda state:
        case (Map.get(state, "current_tok") |> Map.get('ident')) <= initial_ident:
            True ->
                Fcore.Parser.Utils.set_error(
                    state,
                    "The expresions of case must be idented 4 spaces forward in reference to 'case' keyword",
                    Map.get(Map.get(state, "current_tok"), "pos_start"),
                    Map.get(Map.get(state, "current_tok"), "pos_end")
                )
            False -> state

    state = case (Map.get(state, "current_tok") |> Map.get("pos_start") |> Map.get('ln')) > do_line:
        True ->
            loop_while(
                state,
                lambda state, ct:
                    case:
                        Map.get(ct, "type") == "EOF" -> False
                        Map.get(state, "error") != None -> False
                        Map.get(ct, "ident") != initial_ident + 4 -> False
                        True -> True
                ,
                lambda state, ct:
                    state = check_ident(state)

                    cases = Map.get(state, "_cases", [])
                    state = Map.delete(state, "_cases")

                    this_ident = Map.get(state, 'current_tok') |> Map.get('ident')

                    [state, left_expr] = expr(state)

                    case (Map.get(state, 'current_tok') |> Map.get('type')) == 'ARROW':
                        True ->
                            state = advance(state)

                            [state, right_expr] = case (Map.get(state, 'current_tok') |> Map.get('ident')) == this_ident:
                                True -> statement(state)
                                False -> statements(state, this_ident + 4)

                            cases = List.insert_at(cases, -1, [left_expr, right_expr])

                            state |> Map.put('_cases', cases)
                        False ->
                            Fcore.Parser.Utils.set_error(
                                state,
                                "Expected '->'",
                                Map.get(Map.get(state, "current_tok"), "pos_start"),
                                Map.get(Map.get(state, "current_tok"), "pos_end")
                            )
            )
        False ->
            Fcore.Parser.Utils.set_error(
                state,
                "Expected new line after ':'",
                Map.get(Map.get(state, "current_tok"), "pos_start"),
                Map.get(Map.get(state, "current_tok"), "pos_end")
            )

    cases = Map.get(state, '_cases', [])

    case cases:
        [] ->
            state = Fcore.Parser.Utils.set_error(
                state,
                "Case must have at least one case",
                Map.get(Map.get(state, "current_tok"), "pos_start"),
                Map.get(Map.get(state, "current_tok"), "pos_end")
            )
            [state, None]
        _ ->
            state = Map.delete(state, '_cases')

            node = Fcore.Parser.Nodes.make_case_node(
                _expr, cases, pos_start, Map.get(state, 'current_tok') |> Map.get('pos_start')
            )

            [state, node]


def func_def_expr(state):
    state = case (Map.get(state, "current_tok") |> Map.get('ident')) != 0:
        True -> Fcore.Parser.Utils.set_error(
            state,
            "'def' is only allowed in modules scope. TO define functions inside functions use 'lambda' instead.",
            Map.get(Map.get(state, "current_tok"), "pos_start"),
            Map.get(Map.get(state, "current_tok"), "pos_end")
        )
        False -> state

    pos_start = Map.get(state, 'current_tok') |> Map.get('pos_start')
    def_token_ln = pos_start |> Map.get('ln')

    state = advance(state)

    state = case (Map.get(state, "current_tok") |> Map.get('type')) != 'IDENTIFIER':
        True -> Fcore.Parser.Utils.set_error(
            state,
            "Expected a identifier after 'def'.",
            Map.get(Map.get(state, "current_tok"), "pos_start"),
            Map.get(Map.get(state, "current_tok"), "pos_end")
        )
        False -> state

    var_name_tok = Map.get(state, 'current_tok')

    state = advance(state)

    state = case (Map.get(state, "current_tok") |> Map.get('type')) != 'LPAREN':
        True -> Fcore.Parser.Utils.set_error(
            state,
            "Expected '('",
            Map.get(Map.get(state, "current_tok"), "pos_start"),
            Map.get(Map.get(state, "current_tok"), "pos_end")
        )
        False -> state

    state = advance(state)

    [state, arg_name_toks] = resolve_params(state, "RPAREN")

    state = advance(state)

    state = case (Map.get(state, 'current_tok') |> Map.get('type')) == 'DO':
        True -> advance(state)
        False -> Fcore.Parser.Utils.set_error(
            state,
            "Expected ':'",
            Map.get(Map.get(state, "current_tok"), "pos_start"),
            Map.get(Map.get(state, "current_tok"), "pos_end")
        )

    state = case (Map.get(state, 'current_tok') |> Map.get('pos_start') |> Map.get('ln')) > def_token_ln:
        True -> state
        False -> Fcore.Parser.Utils.set_error(
            state,
            "Expected a new line after ':'",
            Map.get(Map.get(state, "current_tok"), "pos_start"),
            Map.get(Map.get(state, "current_tok"), "pos_end")
        )

    [state, body] = statements(state, 4)

    case [arg_name_toks, body]:
        [_, None] ->    [state, None]
        [None, _] ->    [state, None]
        [None, None] -> [state, None]
        _ ->
            node = Fcore.Parser.Nodes.make_funcdef_node(
                var_name_tok, arg_name_toks, body, pos_start
            )

            [state, node]


def resolve_params(state, end_tok):
    state = loop_while(
        state,
        lambda state, ct:
            case:
                Map.get(ct, "type") == "EOF" -> False
                Map.get(ct, "type") == end_tok -> False
                Map.get(state, "error") != None -> False
                True -> True
        ,
        lambda state, ct:
            arg_name_toks = Map.get(state, '_arg_name_toks', [])
            state = Map.delete(state, "_arg_name_toks")

            case Map.get(ct, 'type') == 'IDENTIFIER':
                True ->
                    arg_name_toks = List.insert_at(arg_name_toks, -1, ct)

                    state = advance(state)

                    ct_type = Map.get(state, 'current_tok') |> Map.get('type')

                    case:
                        ct_type == 'COMMA' ->
                            state = advance(state)
                            Map.put(state, '_arg_name_toks', arg_name_toks)
                        ct_type == end_tok ->
                            Map.put(state, '_arg_name_toks', arg_name_toks)
                        True ->
                            Fcore.Parser.Utils.set_error(
                                state,
                                Enum.join(["Expected ',' or '", end_tok, "'"]),
                                Map.get(Map.get(state, "current_tok"), "pos_start"),
                                Map.get(Map.get(state, "current_tok"), "pos_end")
                            )

                False -> Fcore.Parser.Utils.set_error(
                    state,
                    "Expected identifier",
                    Map.get(Map.get(state, "current_tok"), "pos_start"),
                    Map.get(Map.get(state, "current_tok"), "pos_end")
                )
    )

    arg_name_toks = Map.get(state, '_arg_name_toks', [])

    case (Map.get(state, 'current_tok') |> Map.get('type')) == end_tok:
        True ->
            [state |> Map.delete('_arg_name_toks'), arg_name_toks]
        False ->
            state = Fcore.Parser.Utils.set_error(
                state,
                Enum.join(["Expected ", "':'" if end_tok == 'DO' else "')'"]),
                Map.get(Map.get(state, "current_tok"), "pos_start"),
                Map.get(Map.get(state, "current_tok"), "pos_end")
            )

            state = state |> Map.delete('_arg_name_toks')
            [state, None]

def is_keyword(state):
    (Map.get(state, 'current_tok') |> Map.get('type')) == 'IDENTIFIER' and (Map.get(advance(state), 'current_tok') |> Map.get('type')) == 'EQ'

def call_func_expr(state, atom):
    pos_start = Map.get(state, 'pos_start')

    state = advance(state)

    state = case (Map.get(state, 'current_tok') |> Map.get('type')) == 'RPAREN':
        True ->
            state |> Map.put('_arg_nodes', []) |> Map.put('_keywords', {})
        False ->
            loop_while(
                state,
                lambda state, ct:
                    case:
                        Map.get(ct, "type") == "EOF" -> False
                        Map.get(ct, "type") == "RPAREN" -> False
                        Map.get(state, "error") != None -> False
                        True -> True
                ,
                lambda state, ct:
                    arg_nodes = Map.get(state, '_arg_nodes', [])
                    keywords = Map.get(state, '_keywords', {})

                    state = Map.delete(state, '_arg_nodes') |> Map.delete('_keywords')

                    case:
                        not is_keyword(state) and keywords != {} ->
                            Fcore.Parser.Utils.set_error(
                                state,
                                "Non keyword arguments must be placed before any keyword argument",
                                Map.get(state, Map.get('current_tok'), "pos_start"),
                                Map.get(state, Map.get('current_tok'), "pos_end")
                            )
                        True ->
                            updated_fields = case is_keyword(state):
                                True ->
                                    _key = Map.get(state, 'current_tok')
                                    key_value = _key |> Map.get('value')

                                    state = state |> advance() |> advance()

                                    state = case Map.has_key?(keywords, key_value):
                                        True ->
                                            Fcore.Parser.Utils.set_error(
                                                state,
                                                "Duplicated keyword",
                                                Map.get(_key, "pos_start"),
                                                Map.get(Map.get(state, 'current_tok'), "pos_start")
                                            )
                                        False -> state

                                    [state, value] = expr(state)

                                    [state, arg_nodes, Map.merge(keywords, {key_value: value})]
                                False ->
                                    [state, _expr] = expr(state)

                                    [state, List.insert_at(arg_nodes, -1, _expr), keywords]

                            state = Enum.at(updated_fields, 0)
                            arg_nodes = Enum.at(updated_fields, 1)
                            keywords = Enum.at(updated_fields, 2)

                            case Map.get(state, 'current_tok') |> Map.get('type'):
                                'COMMA' ->
                                    state
                                        |> advance()
                                        |> Map.put('_arg_nodes', arg_nodes)
                                        |> Map.put('_keywords', keywords)

                                'RPAREN' ->
                                    state
                                        |> Map.put('_arg_nodes', arg_nodes)
                                        |> Map.put('_keywords', keywords)
                                _ ->
                                    Fcore.Parser.Utils.set_error(
                                        state,
                                        "Expected ')', keyword or ','",
                                        Map.get(Map.get(state, "current_tok"), "pos_start"),
                                        Map.get(Map.get(state, "current_tok"), "pos_end")
                                    )
            )

    arg_nodes = Map.get(state, '_arg_nodes')
    keywords = Map.get(state, '_keywords')

    state = state |> Map.delete('_arg_nodes') |> Map.delete('_keywords')

    state = case (Map.get(state, 'current_tok') |> Map.get('type')) == 'RPAREN':
        True -> state
        False -> Fcore.Parser.Utils.set_error(
            state,
            "Expected ')'",
            Map.get(Map.get(state, "current_tok"), "pos_start"),
            Map.get(Map.get(state, "current_tok"), "pos_end")
        )

    case Map.get(state, 'error'):
        None ->
            pos_end = Map.get(state, 'current_tok') |> Map.get('pos_end')

            state = advance(state)

            node = Fcore.Parser.Nodes.make_call_node(atom, arg_nodes, keywords, pos_end)

            [state, node]
        _ ->
            [state, None]

def lambda_expr(state):
    pos_start = Map.get(state, 'current_tok') |> Map.get('pos_start')
    lambda_token_ln = pos_start |> Map.get('ln')
    lambda_token_ident = Map.get(state, "current_tok") |> Map.get('ident')

    state = advance(state)

    [state, arg_name_toks] = resolve_params(state, 'DO')

    state = case (Map.get(state, 'current_tok') |> Map.get('type')) == 'DO':
        True -> advance(state)
        False -> Fcore.Parser.Utils.set_error(
            state,
            "Expected ':'",
            Map.get(Map.get(state, "current_tok"), "pos_start"),
            Map.get(Map.get(state, "current_tok"), "pos_end")
        )


    [state, body] = case (Map.get(state, 'current_tok') |> Map.get('pos_start') |> Map.get('ln')) == lambda_token_ln:
        True -> expr(state)
        False -> statements(state, lambda_token_ident + 4)

    case [arg_name_toks, body]:
        [_, None] ->    [state, None]
        [None, _] ->    [state, None]
        [None, None] -> [state, None]
        _ ->
            node = Fcore.Parser.Nodes.make_lambda_node(
                None, arg_name_toks, body, pos_start
            )

            [state, node]


def tuple_expr(state, pos_start, first_expr):
    # if the first_expr is None it means
    # that its a a empty tuple being defined
    # using the two parenteces without anything in between: ()

    state = advance(state) if first_expr != None else state

    state = loop_while(
        state,
        lambda state, ct:
            case:
                Map.get(ct, "type") == "EOF" -> False
                Map.get(ct, "type") == "RPAREN" -> False
                Map.get(state, "error") != None -> False
                True -> True
        ,
        lambda state, ct:
            exprs = Map.get(state, '_element_nodes', [])
            state = Map.delete(state, '_element_nodes')

            [state, _expr] = expr(state)

            exprs = List.insert_at(exprs, -1, _expr)

            case Map.get(state, 'current_tok') |> Map.get('type'):
                'COMMA' ->
                    state
                        |> advance()
                        |> Map.put('_element_nodes', exprs)

                'RPAREN' ->
                    state
                        |> Map.put('_element_nodes', exprs)
                _ ->
                    Fcore.Parser.Utils.set_error(
                        state,
                        "Expected ',' or ')'",
                        Map.get(Map.get(state, "current_tok"), "pos_start"),
                        Map.get(Map.get(state, "current_tok"), "pos_end")
                    )
    )

    element_nodes = case first_expr:
        None -> []
        _ ->
            state
                |> Map.get('_element_nodes', [])
                |> List.insert_at(0, first_expr)

    state = state |> Map.delete('_element_nodes')

    state = case (Map.get(state, 'current_tok') |> Map.get('type')) == 'RPAREN':
        True -> state
        False -> Fcore.Parser.Utils.set_error(
            state,
            "Expected ')'",
            Map.get(Map.get(state, "current_tok"), "pos_start"),
            Map.get(Map.get(state, "current_tok"), "pos_end")
        )

    case Map.get(state, 'error'):
        None ->
            pos_end = Map.get(state, 'current_tok') |> Map.get('pos_end')

            state = advance(state)

            node = Fcore.Parser.Nodes.make_tuple_node(element_nodes, pos_start, pos_end)

            [state, node]
        _ ->
            [state, None]

def pattern_match(state, left_node, pos_start):
    state = advance(state)

    valid_left_node = is_map(left_node) and Map.get(left_node, "NodeType") in Fcore.Parser.Nodes.node_types_accept_pattern()

    case:
        Map.get(state, 'error') -> [state, None]
        valid_left_node == False ->
            state = Fcore.Parser.Utils.set_error(
                state,
                "Invalid pattern",
                pos_start,
                Map.get(Map.get(state, "current_tok"), "pos_end")
            )
            [state, None]
        valid_left_node == True ->
            [state, right_node] = expr(state)

            pos_end = Map.get(state, 'current_tok') |> Map.get('pos_start')

            node = Fcore.Parser.Nodes.make_patternmatch_node(
                left_node, right_node, pos_start, pos_end
            )

            [state, node]
