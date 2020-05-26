def execute(tokens):
    state = {
        "error": None,
        "prev_tok": None,
        "current_tok": None,
        "next_tok": None,
        "node": None,
        "_current_tok_idx": -1,
        "_tokens": tokens |> Elixir.Enum.filter(lambda i: i["type"] != 'NEWLINE')
    }

    state |> advance() |> parse() |> Core.Parser.Pos.execute()

def advance(state):
    # before anything, lets check that the states only contains expected keys
    # other wise they are invalid and can have terrible effects in recusive functions
    valid_keys = [
        "error", "current_tok", "next_tok",
        "node", "_current_tok_idx", "_tokens", "prev_tok"
    ]

    state_filtered = state
        |> Elixir.Map.to_list()
        |> Elixir.Enum.filter(lambda key_n_value: Elixir.Kernel.elem(key_n_value, 0) in valid_keys)
        |> Elixir.Map.new()

    case state_filtered != state and state['error'] == None:
        True ->
            # If you get this error. Almost sure that some key
            # wasnt deleted in some loop_while lambdas
            # OR theres some syntax error that wasnt detected
            raise "trying to advance state with invalid keys"
        False -> None

    idx = state["_current_tok_idx"]
    tokens = state["_tokens"]

    idx = idx + 1
    current_tok = tokens |> Elixir.Enum.at(idx, None)

    case idx >= Elixir.Enum.count(tokens):
        True -> state
        False ->
            new_state = {
                "current_tok": current_tok,
                "prev_tok": Elixir.Enum.at(tokens, idx - 1, None) if idx > 0 else None,
                "next_tok": Elixir.Enum.at(tokens, idx + 1, None),
                "_current_tok_idx": idx
            }

            Elixir.Map.merge(state, new_state)

def parse(state):
    [state, node] = statements(state)

    ct = state["current_tok"]

    case state["error"] == None and ct["type"] != "EOF":
        True ->
            Core.Parser.Utils.set_error(
                state,
                "Expected '+' or '-' or '*' or '/'",
                ct["pos_start"],
                ct["pos_end"]
            )
        False ->
            Elixir.Map.merge(state, {"node": node})

def statements(state):
    statements(state, 0)

def statements(state, expected_ident_gte):
    pos_start = state["current_tok"]["pos_start"]

    state = loop_while(
        state,
        lambda state, ct:
            Elixir.Map.get(state, "_break") != True
        ,
        lambda state, ct:
            _statements = Elixir.Map.get(state, "_statements", [])
            state = Elixir.Map.delete(state, '_statements')

            ct_type = ct["type"]

            more_statements = ct["ident"] >= expected_ident_gte

            more_statements = False if ct_type == "RPAREN" else more_statements

            case:
                not more_statements or ct_type == "EOF" ->
                    state
                        |> Elixir.Map.put("_break", True)
                        |> Elixir.Map.put("_statements", _statements)
                True ->
                    [state, _statement] = statement(state)

                    case _statement:
                        None ->
                            state
                                |> Elixir.Map.put("_break", True)
                                |> Elixir.Map.put("_statements", _statements)
                        _ ->
                            Elixir.Map.put(
                                state,
                                "_statements",
                                Elixir.List.insert_at(_statements, -1, _statement)
                            )
    )

    _statements = Elixir.Map.get(state, "_statements", [])
    state = Elixir.Map.delete(state, "_statements") |> Elixir.Map.delete("_break")

    case:
        state["error"] != None ->
            [state, None]
        _statements == [] ->
            ct = state["current_tok"]

            state = Core.Parser.Utils.set_error(
                state,
                "Empty staments are not allowed",
                ct["pos_start"],
                ct["pos_end"]
            )
            [state, None]
        True ->
            pos_end = state["current_tok"]["pos_end"]
            node = Core.Parser.Nodes.make_statements_node(_statements, pos_start, pos_end)

            [state, node]


def statement(state):
    ct = state['current_tok']
    pos_start = ct['pos_start']

    [state, node] = case:
        Core.Parser.Utils.tok_matchs(ct, "KEYWORD", "def") ->
            func_def_expr(state)
        Core.Parser.Utils.tok_matchs(ct, 'KEYWORD', 'raise') ->
            [state, _expr] = state |> advance() |> expr()

            node = Core.Parser.Nodes.make_raise_node(_expr, pos_start)
            [state, node]
        True ->
            [state, _expr] = expr(state)

            case state["error"]:
                None -> [state, _expr]
                _ ->
                    ct = state["current_tok"]

                    state = Core.Parser.Utils.set_error(
                        state,
                        "Expected int, float, variable, 'not', '+', '-', '(' or '['",
                        ct["pos_start"],
                        ct["pos_end"]
                    )
                    [state, None]

    case (state['current_tok']['type']) == 'EQ':
        True -> pattern_match(state, node, pos_start)
        False -> [state, node]

def expr(state):
    ct = state['current_tok']
    ct_type = ct['type']

    [state, node] = bin_op(state, &comp_expr/1, [['KEYWORD', 'and'], ['KEYWORD', 'or']], None)

    ct = state["current_tok"]

    case:
        Core.Parser.Utils.tok_matchs(ct, 'KEYWORD', 'if') ->
            if_expr(state, node)
        ct['type'] == 'PIPE' ->
            pipe_expr(state, node)
        Core.Parser.Utils.tok_matchs(ct, 'KEYWORD', 'in') ->
            state = advance(state)

            [state, right_node] = expr(state)

            node = Core.Parser.Nodes.make_in_node(
                node, right_node
            )
            [state, node]
        True -> [state, node]


def comp_expr(state):
    ct = state["current_tok"]

    case Core.Parser.Utils.tok_matchs(ct, "KEYWORD", 'not'):
        True ->
            state = advance(state)

            [state, c_node] = comp_expr(state)

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
    call(state, None)

def call(state, _atom):
    [state, _atom] = case _atom:
        None -> atom(state)
        _ -> [state, _atom]

    get_info = lambda state:
        ct = state['current_tok']
        ct_type = ct['type']
        ct_line = ct['pos_start']['ln']

        prev_tok_ln = state
            |> Elixir.Map.get('_tokens')
            |> Elixir.Enum.at(Elixir.Map.get(state, '_current_tok_idx') - 1)
            |> Elixir.Map.get('pos_end')
            |> Elixir.Map.get('ln')

        (ct, ct_type, ct_line, prev_tok_ln)

    # we must only consider as a call node if the previous node is
    # in the same line that the left parent

    (ct, ct_type, ct_line, prev_tok_ln) = get_info(state)

    [state, _atom] = case:
        ct_type == 'LPAREN' and ct_line == prev_tok_ln -> call_func_expr(state, _atom)
        ct_type == 'LSQUARE' and ct_line == prev_tok_ln -> static_access_expr(state, _atom)
        True -> [state, _atom]

    (ct, ct_type, ct_line, prev_tok_ln) = get_info(state)

    case ct_line == prev_tok_ln and ct_type in ['LPAREN', 'LSQUARE']:
        True -> call(state, _atom)
        False -> [state, _atom]

def factor(state):
    ct = state["current_tok"]
    ct_type = ct['type']

    case ct_type in ['PLUS', 'MINUS']:
        True ->
            state = state |> advance()

            [state, _factor] = factor(state)

            case state["error"]:
                None ->
                    node = Core.Parser.Nodes.make_unary_node(ct, _factor)
                    [state, node]
                _ -> [state, None]

        False -> power(state)

def atom(state):
    ct = state["current_tok"]
    ct_type = ct['type']

    pos_start = ct['pos_start']

    case:
        ct_type in ['INT', 'FLOAT'] ->
            node = Core.Parser.Nodes.make_number_node(ct)
            [state |> advance(), node]
        ct_type == 'STRING' ->
            node = Core.Parser.Nodes.make_string_node(ct)
            [state |> advance(), node]
        ct_type == 'IDENTIFIER' or ct_type == 'PIN' ->
            is_pinned = ct_type == 'PIN'

            (state, ct) = (advance(state), Elixir.Map.get(advance(state), 'current_tok')) if is_pinned else (state, ct)

            node = Core.Parser.Nodes.make_varaccess_node(ct, is_pinned)
            [state |> advance(), node]
        ct_type == 'ATOM' ->
            node = Core.Parser.Nodes.make_atom_node(ct)
            [state |> advance(), node]
        ct_type == 'ECOM' ->
            func_as_var_expr(state)
        ct_type == 'LPAREN' ->
            state = advance(state)

            [state, _expr] = case (state['current_tok']['type']) == 'RPAREN':
                True -> [state, None]
                False -> expr(state)

            ct_type = state['current_tok']['type']

            case:
                # if the _expr is None it means that we are defining
                # a tuple without elements. Eg: ()
                ct_type == 'COMMA' or _expr == None ->
                    tuple_expr(state, pos_start, _expr)
                ct_type == 'RPAREN' ->
                    state = advance(state)
                    [state, _expr]
                True ->
                    ct = state['current_tok']

                    state = Core.Parser.Utils.set_error(
                        state, "Expected ')'", ct["pos_start"], ct["pos_end"]
                    )
                    [state, None]
        ct_type == 'LSQUARE' -> list_expr(state)
        ct_type == 'LCURLY' -> map_expr(state)
        Core.Parser.Utils.tok_matchs(ct, "KEYWORD", "case") ->
            case_expr(state)
        Core.Parser.Utils.tok_matchs(ct, "KEYWORD", "lambda") ->
            lambda_expr(state)
        Core.Parser.Utils.tok_matchs(ct, 'KEYWORD', 'try') ->
            try_except_expr(state)
        True ->
            state = Core.Parser.Utils.set_error(
                state,
                Elixir.Enum.join([
                    "Expected int, float, identifier, '+', '-', '(', '[', if, def, lambda or case. ",
                    "Received: ",
                    ct_type
                ]),
                ct["pos_start"],
                ct["pos_end"]
            )
            [state, None]


def loop_while(st, while_func, do_func):
    ct = st["current_tok"]

    valid = while_func(st, ct)

    case valid:
        True -> do_func(st, ct) |> loop_while(while_func, do_func)
        False -> st

def bin_op(state, func_a, ops, func_b):
    func_b = func_b if func_b != None else func_a

    [state, first_left] = func_a(state)

    ct = state["current_tok"]

    state = loop_while(
        state,
        lambda state, ct:
            case:
                ct["type"] == "EOF" -> False
                state["error"] != None -> False
                Elixir.Enum.member?(ops, ct["type"]) or Elixir.Enum.member?(ops, [ct["type"], ct["value"]]) -> True
                True -> False
        ,
        lambda state, ct:
            left = Elixir.Map.get(state, "_node", first_left)
            state = Elixir.Map.delete(state, "_node")

            op_tok = state['current_tok']
            state = advance(state)

            [state, right] = func_b(state)

            case state["error"]:
                None ->
                    left = Core.Parser.Nodes.make_bin_op_node(left, op_tok, right)
                    Elixir.Map.put(state, "_node", left)
                _ -> state
    )

    left = Elixir.Map.get(state, '_node', first_left)
    state = Elixir.Map.delete(state, '_node')

    [state, left]

def list_expr(state):
    pos_start = state["current_tok"]["pos_start"]

    state = loop_while(
        state,
        lambda state, ct:
            case:
                ct["type"] == "RSQUARE" -> False
                ct["type"] == "EOF" -> False
                state["error"] != None -> False
                True -> True
        ,
        lambda state, ct:
            element_nodes = Elixir.Map.get(state, "_element_nodes", [])
            state = Elixir.Map.delete(state, "_element_nodes")

            state = state if ct["type"] == "COMMA" and element_nodes == [] else advance(state)

            case state["current_tok"]["type"]:
                "RSQUARE" -> state
                _ ->
                    [state, _expr] = expr(state)

                    Elixir.Map.put(
                        state |> Elixir.Map.put("_element_nodes", element_nodes),
                        "_element_nodes",
                        Elixir.List.flatten([element_nodes, _expr])
                    )
    )

    ct = state["current_tok"]

    case ct['type']:
        'RSQUARE' ->
            element_nodes = Elixir.Map.get(state, "_element_nodes", [])
            state = Elixir.Map.delete(state, "_element_nodes")

            pos_end = state["current_tok"]["pos_end"]

            node = Core.Parser.Nodes.make_list_node(element_nodes, pos_start, pos_end)

            state = advance(state)

            [state, node]
        _ ->
            state = Core.Parser.Utils.set_error(
                state,
                "Expected ']'",
                ct["pos_start"],
                ct["pos_end"]
            )
            [state, None]


def map_expr(state):
    pos_start = state["current_tok"]["pos_start"]

    map_get_pairs = lambda state:
        [state, key] = expr(state)

        case:
            (state["current_tok"]["type"]) == "DO" ->
                state = advance(state)

                [state, value] = expr(state)

                [state, {key: value}]
            True ->
                ct = state["current_tok"]
                Core.Parser.Utils.set_error(
                    state,
                    "Empty staments are not allowed",
                    ct["pos_start"],
                    ct["pos_end"]
                )
                [state, None]

    state = loop_while(
        state,
        lambda state, ct:
            case:
                ct["type"] == "RCURLY" -> False
                ct["type"] == "EOF" -> False
                state["error"] != None -> False
                True -> True
        ,
        lambda state, ct:
            pairs = Elixir.Map.get(state, "_pairs", {})
            state = Elixir.Map.delete(state, "_pairs")

            state = advance(state)

            case state["current_tok"]["type"]:
                "RCURLY" -> state
                _ ->
                    [state, map] = map_get_pairs(state)

                    case map:
                        None -> state
                        _ -> Elixir.Map.put(state, "_pairs", Elixir.Map.merge(pairs, map))
    )

    ct = state["current_tok"]

    case ct['type']:
        'RCURLY' ->
            pairs = Elixir.Map.get(state, "_pairs", {})
                |> Elixir.Map.to_list()
                |> Elixir.Enum.map(lambda i: [Elixir.Kernel.elem(i, 0), Elixir.Kernel.elem(i, 1)])

            pos_end = state["current_tok"]["pos_end"]

            node = Core.Parser.Nodes.make_map_node(pairs, pos_start, pos_end)

            state = state |> Elixir.Map.delete("_pairs") |> Elixir.Map.delete("_break") |> advance()

            [state, node]
        _ ->
            state = Core.Parser.Utils.set_error(
                state,
                "Expected '}'",
                ct["pos_start"],
                ct["pos_end"]
            )
            [state, None]


def if_expr(state, expr_for_true):
    state = advance(state)

    [state, condition] = expr(state)

    case Core.Parser.Utils.tok_matchs(state["current_tok"], "KEYWORD", "else"):
        True ->
            state = advance(state)

            [state, expr_for_false] = expr(state)

            node = Core.Parser.Nodes.make_if_node(
                condition, expr_for_true, expr_for_false
            )
            [state, node]
        False ->
            state = Core.Parser.Utils.set_error(
                state,
                "Expected 'else'",
                state["current_tok"]["pos_start"],
                state["current_tok"]["pos_end"]
            )

            [state, None]


def pipe_expr(state, left_node):
    state = advance(state)

    [state, right_node] = expr(state)

    case state['error']:
        None ->
            node = Core.Parser.Nodes.make_pipe_node(left_node, right_node)
            [state, node]
        _ ->
            state = Core.Parser.Utils.set_error(
                state,
                "Expected and expression after '|>'",
                state["current_tok"]["pos_start"],
                state["current_tok"]["pos_end"]
            )

            [state, None]

def func_as_var_expr(state):
    pos_start = state['current_tok']['pos_start']
    state = advance(state)

    sequence = [
        state['current_tok']['type'],
        state |> advance() |> Elixir.Map.get('current_tok') |> Elixir.Map.get('type'),
        state |> advance() |> advance() |> Elixir.Map.get('current_tok') |> Elixir.Map.get('type')
    ]

    case sequence:
        ["IDENTIFIER", "DIV", "INT"] ->
            var_name_tok = state['current_tok']

            state = advance(state)
            state = advance(state)

            arity = state['current_tok']
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
                state["current_tok"]["pos_start"],
                state["current_tok"]["pos_end"]
            )
            [state, None]
        ['IDENTIFIER', "DIV", _] ->
            state = state |> advance() |> advance()
            state = Core.Parser.Utils.set_error(
                state,
                "Expected arity number as int",
                state["current_tok"]["pos_start"],
                state["current_tok"]["pos_end"]
            )
            [state, None]
        [_, _, _] ->
            state = Core.Parser.Utils.set_error(
                state,
                "Expected the function name and arity. E.g: &sum/2",
                state["current_tok"]["pos_start"],
                state["current_tok"]["pos_end"]
            )
            [state, None]


def case_expr(state):
    pos_start = state['current_tok']['pos_start']
    initial_ident = state['current_tok']['ident']

    state = advance(state)

    is_cond = (state["current_tok"]["type"]) == "DO"

    [state, _expr] = case is_cond:
        True -> [state, None]
        False -> expr(state)

    do_line = pos_start['ln']
    state = advance(state)

    check_ident = lambda state:
        case state["current_tok"]['ident'] <= initial_ident:
            True ->
                Core.Parser.Utils.set_error(
                    state,
                    "The expresions of case must be idented 4 spaces forward in reference to 'case' keyword",
                    state["current_tok"]["pos_start"],
                    state["current_tok"]["pos_end"]
                )
            False -> state

    state = case state["current_tok"]["pos_start"]['ln'] > do_line:
        True ->
            loop_while(
                state,
                lambda state, ct:
                    case:
                        ct["type"] == "EOF" -> False
                        state["error"] != None -> False
                        ct["ident"] != initial_ident + 4 -> False
                        True -> True
                ,
                lambda state, ct:
                    state = check_ident(state)

                    cases = Elixir.Map.get(state, "_cases", [])
                    state = Elixir.Map.delete(state, "_cases")

                    this_ident = state['current_tok']['ident']

                    [state, left_expr] = expr(state)

                    case (state['current_tok']['type']) == 'ARROW':
                        True ->
                            state = advance(state)

                            [state, right_expr] = case (state['current_tok']['ident']) == this_ident:
                                True -> statement(state)
                                False -> statements(state, this_ident + 4)

                            cases = Elixir.List.insert_at(cases, -1, [left_expr, right_expr])

                            state |> Elixir.Map.put('_cases', cases)
                        False ->
                            Core.Parser.Utils.set_error(
                                state,
                                "Expected '->'",
                                state["current_tok"]["pos_start"],
                                state["current_tok"]["pos_end"]
                            )
            )
        False ->
            Core.Parser.Utils.set_error(
                state,
                "Expected new line after ':'",
                state["current_tok"]["pos_start"],
                state["current_tok"]["pos_end"]
            )

    cases = Elixir.Map.get(state, '_cases', [])

    case cases:
        [] ->
            state = Core.Parser.Utils.set_error(
                state,
                "Case must have at least one case",
                state["current_tok"]["pos_start"],
                state["current_tok"]["pos_end"]
            )
            [state, None]
        _ ->
            state = Elixir.Map.delete(state, '_cases')

            node = Core.Parser.Nodes.make_case_node(
                _expr, cases, pos_start, state['current_tok']['pos_start']
            )

            [state, node]


def func_def_expr(state):
    state = case state["current_tok"]['ident'] != 0:
        True -> Core.Parser.Utils.set_error(
            state,
            "'def' is only allowed in modules scope. TO define functions inside functions use 'lambda' instead.",
            state["current_tok"]["pos_start"],
            state["current_tok"]["pos_end"]
        )
        False -> state

    pos_start = state['current_tok']['pos_start']
    def_token_ln = pos_start['ln']

    state = advance(state)

    state = case state["current_tok"]['type'] != 'IDENTIFIER':
        True -> Core.Parser.Utils.set_error(
            state,
            "Expected a identifier after 'def'.",
            Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_start"),
            Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
        )
        False -> state

    var_name_tok = state['current_tok']

    state = advance(state)

    state = case (state["current_tok"]['type']) != 'LPAREN':
        True -> Core.Parser.Utils.set_error(
            state,
            "Expected '('",
            state["current_tok"]["pos_start"],
            state["current_tok"]["pos_end"]
        )
        False -> state

    state = advance(state)

    [state, arg_name_toks] = resolve_params(state, "RPAREN")

    state = advance(state)

    state = case (state['current_tok']['type']) == 'DO':
        True -> advance(state)
        False -> Core.Parser.Utils.set_error(
            state,
            "Expected ':'",
            state["current_tok"]["pos_start"],
            state["current_tok"]["pos_end"]
        )

    state = case (state['current_tok']['pos_start']['ln']) > def_token_ln:
        True -> state
        False -> Core.Parser.Utils.set_error(
            state,
            "Expected a new line after ':'",
            state["current_tok"]["pos_start"],
            state["current_tok"]["pos_end"]
        )

    # Here we check if a doc string exists
    # but we only consider the MULLINESTRING Token as a docstring
    # if there's any other statements in the function
    # otherwise this token is just the return of the function

    ct_type = state["current_tok"]['type']

    (state, docstring) = case ct_type == 'MULLINESTRING' and advance(state)['current_tok']['ident'] > def_token_ln:
        True -> (advance(state), state["current_tok"])
        False -> (state, None)

    # evaluates body of function
    [state, body] = statements(state, 4)

    case [arg_name_toks, body]:
        [_, None] ->    [state, None]
        [None, _] ->    [state, None]
        [None, None] -> [state, None]
        _ ->
            node = Core.Parser.Nodes.make_funcdef_node(
                var_name_tok, arg_name_toks, body, docstring, pos_start
            )

            [state, node]


def resolve_params(state, end_tok):
    state = loop_while(
        state,
        lambda state, ct:
            case:
                ct["type"] == "EOF" -> False
                ct["type"] == end_tok -> False
                state["error"] != None -> False
                True -> True
        ,
        lambda state, ct:
            arg_name_toks = Elixir.Map.get(state, '_arg_name_toks', [])
            state = Elixir.Map.delete(state, "_arg_name_toks")

            case ct['type'] == 'IDENTIFIER':
                True ->
                    arg_name_toks = Elixir.List.insert_at(arg_name_toks, -1, ct)

                    state = advance(state)

                    ct_type = state['current_tok']['type']

                    case:
                        ct_type == 'COMMA' ->
                            state = advance(state)
                            Elixir.Map.put(state, '_arg_name_toks', arg_name_toks)
                        ct_type == end_tok ->
                            Elixir.Map.put(state, '_arg_name_toks', arg_name_toks)
                        True ->
                            Core.Parser.Utils.set_error(
                                state,
                                Elixir.Enum.join(["Expected ',' or '", end_tok, "'"]),
                                state["current_tok"]["pos_start"],
                                state["current_tok"]["pos_end"]
                            )

                False -> Core.Parser.Utils.set_error(
                    state,
                    "Expected identifier",
                    state["current_tok"]["pos_start"],
                    state["current_tok"]["pos_end"]
                )
    )

    arg_name_toks = Elixir.Map.get(state, '_arg_name_toks', [])

    case (state['current_tok']['type']) == end_tok:
        True ->
            [state |> Elixir.Map.delete('_arg_name_toks'), arg_name_toks]
        False ->
            state = Core.Parser.Utils.set_error(
                state,
                Elixir.Enum.join(["Expected ", "':'" if end_tok == 'DO' else "')'"]),
                state["current_tok"]["pos_start"],
                state["current_tok"]["pos_end"]
            )

            state = state |> Elixir.Map.delete('_arg_name_toks')
            [state, None]

def is_func_keyword(state):
    state['current_tok']['type'] == 'IDENTIFIER' and advance(state)['current_tok']['type'] == 'EQ'

def call_func_expr(state, atom):
    pos_start = state["current_tok"]["pos_start"]

    state = advance(state)

    state = case (state['current_tok']['type']) == 'RPAREN':
        True ->
            state |> Elixir.Map.put('_arg_nodes', []) |> Elixir.Map.put('_keywords', {})
        False ->
            loop_while(
                state,
                lambda state, ct:
                    case:
                        ct["type"] == "EOF" -> False
                        ct["type"] == "RPAREN" -> False
                        state["error"] != None -> False
                        True -> True
                ,
                lambda state, ct:
                    arg_nodes = Elixir.Map.get(state, '_arg_nodes', [])
                    keywords = Elixir.Map.get(state, '_keywords', {})

                    state = Elixir.Map.delete(state, '_arg_nodes') |> Elixir.Map.delete('_keywords')

                    case:
                        not is_func_keyword(state) and keywords != {} ->
                            Core.Parser.Utils.set_error(
                                state,
                                "Non keyword arguments must be placed before any keyword argument",
                                state['current_tok']["pos_start"],
                                state['current_tok']["pos_end"]
                            )
                        True ->
                            updated_fields = case is_func_keyword(state):
                                True ->
                                    _key = state['current_tok']
                                    key_value = _key |> Elixir.Map.get('value')

                                    state = state |> advance() |> advance()

                                    state = case Elixir.Map.has_key?(keywords, key_value):
                                        True ->
                                            Core.Parser.Utils.set_error(
                                                state,
                                                "Duplicated keyword",
                                                _key["pos_start"],
                                                state['current_tok']["pos_start"]
                                            )
                                        False -> state

                                    [state, value] = expr(state)

                                    [state, arg_nodes, Elixir.Map.merge(keywords, {key_value: value})]
                                False ->
                                    [state, _expr] = expr(state)

                                    [state, Elixir.List.insert_at(arg_nodes, -1, _expr), keywords]

                            state = Elixir.Enum.at(updated_fields, 0)
                            arg_nodes = Elixir.Enum.at(updated_fields, 1)
                            keywords = Elixir.Enum.at(updated_fields, 2)

                            case state['current_tok']['type']:
                                'COMMA' ->
                                    state
                                        |> advance()
                                        |> Elixir.Map.put('_arg_nodes', arg_nodes)
                                        |> Elixir.Map.put('_keywords', keywords)

                                'RPAREN' ->
                                    state
                                        |> Elixir.Map.put('_arg_nodes', arg_nodes)
                                        |> Elixir.Map.put('_keywords', keywords)
                                _ ->
                                    Core.Parser.Utils.set_error(
                                        state,
                                        "Expected ')', keyword or ','",
                                        state["current_tok"]["pos_start"],
                                        state["current_tok"]["pos_end"]
                                    )
            )

    arg_nodes = Elixir.Map.get(state, '_arg_nodes')
    keywords = Elixir.Map.get(state, '_keywords')

    state = state |> Elixir.Map.delete('_arg_nodes') |> Elixir.Map.delete('_keywords')

    state = case (state['current_tok']['type']) == 'RPAREN':
        True -> state
        False -> Core.Parser.Utils.set_error(
            state,
            "Expected ')'",
            state["current_tok"]["pos_start"],
            state["current_tok"]["pos_end"]
        )

    case state['error']:
        None ->
            pos_end = state['current_tok'] |> Elixir.Map.get('pos_end')

            state = advance(state)

            node = Core.Parser.Nodes.make_call_node(atom, arg_nodes, keywords, pos_end)

            [state, node]
        _ ->
            [state, None]

def lambda_expr(state):
    pos_start = state['current_tok']['pos_start']
    lambda_token_ln = pos_start['ln']
    lambda_token_ident = state["current_tok"]['ident']

    state = advance(state)

    [state, arg_name_toks] = resolve_params(state, 'DO')

    state = case (state['current_tok']['type']) == 'DO':
        True -> advance(state)
        False -> Core.Parser.Utils.set_error(
            state,
            "Expected ':'",
            state["current_tok"]["pos_start"],
            state["current_tok"]["pos_end"]
        )


    [state, body] = case (state['current_tok']['pos_start']['ln']) == lambda_token_ln:
        True -> expr(state)
        False -> statements(state, lambda_token_ident + 4)

    case [arg_name_toks, body]:
        [_, None] ->    [state, None]
        [None, _] ->    [state, None]
        [None, None] -> [state, None]
        _ ->
            node = Core.Parser.Nodes.make_lambda_node(
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
                ct["type"] == "EOF" -> False
                ct["type"] == "RPAREN" -> False
                state["error"] != None -> False
                True -> True
        ,
        lambda state, ct:
            exprs = Elixir.Map.get(state, '_element_nodes', [])
            state = Elixir.Map.delete(state, '_element_nodes')

            [state, _expr] = expr(state)

            exprs = Elixir.List.insert_at(exprs, -1, _expr)

            case state['current_tok']['type']:
                'COMMA' ->
                    state
                        |> advance()
                        |> Elixir.Map.put('_element_nodes', exprs)

                'RPAREN' ->
                    state
                        |> Elixir.Map.put('_element_nodes', exprs)
                _ ->
                    Core.Parser.Utils.set_error(
                        state,
                        "Expected ',' or ')'",
                        state["current_tok"]["pos_start"],
                        state["current_tok"]["pos_end"]
                    )
    )

    element_nodes = case first_expr:
        None -> []
        _ ->
            state
                |> Elixir.Map.get('_element_nodes', [])
                |> Elixir.List.insert_at(0, first_expr)

    state = state |> Elixir.Map.delete('_element_nodes')

    state = case (state['current_tok']['type']) == 'RPAREN':
        True -> state
        False -> Core.Parser.Utils.set_error(
            state,
            "Expected ')'",
            state["current_tok"]["pos_start"],
            state["current_tok"]["pos_end"]
        )

    case state['error']:
        None ->
            pos_end = state['current_tok']['pos_end']

            state = advance(state)

            node = Core.Parser.Nodes.make_tuple_node(element_nodes, pos_start, pos_end)

            [state, node]
        _ ->
            [state, None]

def pattern_match(state, left_node, pos_start):
    state = advance(state)

    valid_left_node = Elixir.Kernel.is_map(left_node) and Elixir.Map.get(left_node, "NodeType") in Core.Parser.Nodes.node_types_accept_pattern()

    case:
        state['error'] -> [state, None]
        valid_left_node == False ->
            state = Core.Parser.Utils.set_error(
                state,
                "Invalid pattern",
                pos_start,
                state["current_tok"]["pos_end"]
            )
            [state, None]
        valid_left_node == True ->
            [state, right_node] = expr(state)

            pos_end = state['current_tok']['pos_start']

            node = Core.Parser.Nodes.make_patternmatch_node(
                left_node, right_node, pos_start, pos_end
            )

            [state, node]

def static_access_expr(state, left_node):
    state = advance(state)

    [state, node_value] = expr(state)

    state = case state['current_tok']['type']:
        'RSQUARE' -> state
        _ ->
            Core.Parser.Utils.set_error(
                state,
                "Expected ]",
                state["current_tok"]["pos_start"],
                state["current_tok"]["pos_end"]
            )

    case state['error']:
        None ->
            pos_end = state['current_tok']['pos_end']
            node = Core.Parser.Nodes.make_staticaccess_node(left_node, node_value, pos_end)

            state = advance(state)

            [state, node]
        _ -> [state, None]


def handle_do_new_line(state, base_line):
    # helper to set error in state if theres no DO or
    # ift dont have a new line, correctly idented, after a DO

    state = case state['current_tok']['type']:
        'DO' -> advance(state)
        _ ->
            Core.Parser.Utils.set_error(
                state, "Expected ':'",
                state["current_tok"]["pos_start"],
                state["current_tok"]["pos_end"]
            )

    state = case state['current_tok']['pos_start']['ln'] > base_line:
        True -> state
        False -> Core.Parser.Utils.set_error(
            state,
            "Expected a new line after ':'",
            state["current_tok"]["pos_start"],
            state["current_tok"]["pos_end"]
        )

    state


def handle_except_blocks(state, base_line, prev_blocks):
    (state, except_expr) = case state['current_tok']['type'] != 'IDENTIFIER':
        True ->
            state = Core.Parser.Utils.set_error(
                state, "Expected identifier",
                state["current_tok"]["pos_start"],
                state["current_tok"]["pos_end"]
            )
            (state, None)
        False ->
            (advance(state), state['current_tok']['value'])

    (state, alias) = case Core.Parser.Utils.tok_matchs(state['current_tok'], 'KEYWORD', 'as'):
        True ->
            state = advance(state)

            case state['current_tok']['type'] != 'IDENTIFIER':
                True ->
                    state = Core.Parser.Utils.set_error(
                        state, "Expected identifier",
                        state["current_tok"]["pos_start"],
                        state["current_tok"]["pos_end"]
                    )
                    (state, None)
                False ->
                    (advance(state), state['current_tok']['value'])
        False -> (state, None)

    state = handle_do_new_line(state, base_line)

    [state, block] = statements(state)

    new_list_blocks = Elixir.List.insert_at(prev_blocks, -1, (except_expr, alias, block))

    case Core.Parser.Utils.tok_matchs(state['current_tok'], 'KEYWORD', 'except'):
        True ->
            advance(state) |> handle_except_blocks(base_line, new_list_blocks)
        False ->
            [state, new_list_blocks]


def try_except_expr(state):
    pos_start = state['current_tok']['pos_start']
    try_token_ln = pos_start['ln']
    try_token_ident = state['current_tok']['ident']

    state = advance(state)

    ## TRY BLOCK #################################

    state = handle_do_new_line(state, try_token_ln)

    [state, try_statements] = statements(state, try_token_ident + 4)

    ## EXCEPT BLOCK #################################

    state = case Core.Parser.Utils.tok_matchs(state['current_tok'], 'KEYWORD', 'except'):
        True -> advance(state)
        False ->
            Core.Parser.Utils.set_error(
                state, "Expected 'except' keyword",
                state["current_tok"]["pos_start"],
                state["current_tok"]["pos_end"]
            )

    [state, except_blocks] = handle_except_blocks(state, try_token_ln, [])

    ## FINALLY BLOCK #################################

    (state, finally_block) = case Core.Parser.Utils.tok_matchs(state['current_tok'], 'KEYWORD', 'finally'):
        True -> statements(state, try_token_ident + 4)
        False -> (state, None)

    pos_end = state['current_tok']['pos_start']

    node = Core.Parser.Nodes.make_try_node(try_statements, except_blocks, finally_block, pos_start, pos_end)

    [state, node]