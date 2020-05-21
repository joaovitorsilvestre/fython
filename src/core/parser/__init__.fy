def execute(tokens):
    state = {
        "error": None,
        "prev_tok": None,
        "current_tok": None,
        "next_tok": None,
        "node": None,
        "_current_tok_idx": -1,
        "_tokens": tokens |> Elixir.Enum.filter(lambda i: Elixir.Map.get(i, "type") != 'NEWLINE')
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

    case state_filtered != state and Elixir.Map.get(state, 'error') == None:
        True ->
            # If you get this error. Almost sure that some key
            # wasnt deleted in some loop_while lambdas
            # OR theres some syntax error that wasnt detected
            raise "trying to advance state with invalid keys"
        False -> None

    idx = state |> Elixir.Map.get("_current_tok_idx")
    tokens = state |> Elixir.Map.get("_tokens")

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

    ct = Elixir.Map.get(state, "current_tok")

    case Elixir.Map.get(state, "error") == None and Elixir.Map.get(ct, "type") != "EOF":
        True ->
            Core.Parser.Utils.set_error(
                state,
                "Expected '+' or '-' or '*' or '/'",
                Elixir.Map.get(ct, "pos_start"),
                Elixir.Map.get(ct, "pos_end")
            )
        False ->
            Elixir.Map.merge(state, {"node": node})

def statements(state):
    statements(state, 0)

def statements(state, expected_ident_gte):
    pos_start = Elixir.Map.get(state, "current_tok") |> Elixir.Map.get("pos_start")

    state = loop_while(
        state,
        lambda state, ct:
            Elixir.Map.get(state, "_break") != True
        ,
        lambda state, ct:
            _statements = Elixir.Map.get(state, "_statements", [])
            state = Elixir.Map.delete(state, '_statements')

            ct_type = Elixir.Map.get(ct, "type")

            more_statements = Elixir.Map.get(ct, "ident") >= expected_ident_gte

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
        Elixir.Map.get(state, "error") != None ->
            [state, None]
        _statements == [] ->
            ct = Elixir.Map.get(state, "current_tok")

            state = Core.Parser.Utils.set_error(
                state,
                "Empty staments are not allowed",
                Elixir.Map.get(ct, "pos_start"),
                Elixir.Map.get(ct, "pos_end")
            )
            [state, None]
        True ->
            pos_end = Elixir.Map.get(state, "current_tok") |> Elixir.Map.get("pos_end")
            node = Core.Parser.Nodes.make_statements_node(_statements, pos_start, pos_end)

            [state, node]


def statement(state):
    ct = Elixir.Map.get(state, 'current_tok')
    pos_start = Elixir.Map.get(ct, 'pos_start')

    [state, node] = case:
        Core.Parser.Utils.tok_matchs(ct, 'KEYWORD', 'raise') ->
            pos_start = Elixir.Map.get(ct, 'pos_start')

            [state, _expr] = state |> advance() |> expr()

            node = Core.Parser.Nodes.make_raise_node(_expr, pos_start)
            [state, node]
        True ->
            [state, _expr] = expr(state)

            case Elixir.Map.get(state, "error"):
                None -> [state, _expr]
                _ ->
                    ct = Elixir.Map.get(state, "current_tok")

                    state = Core.Parser.Utils.set_error(
                        state,
                        "Expected int, float, variable, 'not', '+', '-', '(' or '['",
                        Elixir.Map.get(ct, "pos_start"),
                        Elixir.Map.get(ct, "pos_end")
                    )
                    [state, None]

    case (Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('type')) == 'EQ':
        True -> pattern_match(state, node, pos_start)
        False -> [state, node]

def expr(state):
    ct = state |> Elixir.Map.get('current_tok')
    ct_type = ct |> Elixir.Map.get('type')

    _and = ["KEYWORD", "and"]
    _or = ["KEYWORD", "or"]

    [state, node] = bin_op(state, &comp_expr/1, [_and, _or], None)

    ct = Elixir.Map.get(state, "current_tok")

    case:
        Core.Parser.Utils.tok_matchs(ct, 'KEYWORD', 'if') ->
            if_expr(state, node)
        Elixir.Map.get(ct, 'type') == 'PIPE' ->
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
    ct = Elixir.Map.get(state, "current_tok")

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
        ct = Elixir.Map.get(state, 'current_tok')
        ct_type = Elixir.Map.get(ct, 'type')
        ct_line = Elixir.Map.get(ct, 'pos_start') |> Elixir.Map.get('ln')

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
    ct = Elixir.Map.get(state, "current_tok")
    ct_type = ct |> Elixir.Map.get('type')

    case ct_type in ['PLUS', 'MINUS']:
        True ->
            state = state |> advance()

            [state, _factor] = factor(state)

            case Elixir.Map.get(state, "error"):
                None ->
                    node = Core.Parser.Nodes.make_unary_node(ct, _factor)
                    [state, node]
                _ -> [state, None]

        False -> power(state)

def atom(state):
    ct = Elixir.Map.get(state, "current_tok")
    ct_type = ct |> Elixir.Map.get('type')

    pos_start = Elixir.Map.get(ct, 'pos_start')

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

            [state, _expr] = case (Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('type')) == 'RPAREN':
                True -> [state, None]
                False -> expr(state)

            ct_type = Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('type')

            case:
                # if the _expr is None it means that we are defining
                # a tuple without elements. Eg: ()
                ct_type == 'COMMA' or _expr == None ->
                    tuple_expr(state, pos_start, _expr)
                ct_type == 'RPAREN' ->
                    state = advance(state)
                    [state, _expr]
                True ->
                    ct = Elixir.Map.get(state, 'current_tok')

                    state = Core.Parser.Utils.set_error(
                        state, "Expected ')'", Elixir.Map.get(ct, "pos_start"), Elixir.Map.get(ct, "pos_end")
                    )
                    [state, None]
        ct_type == 'LSQUARE' -> list_expr(state)
        ct_type == 'LCURLY' -> map_expr(state)
        Core.Parser.Utils.tok_matchs(ct, "KEYWORD", "case") ->
            case_expr(state)
        Core.Parser.Utils.tok_matchs(ct, "KEYWORD", "def") ->
            func_def_expr(state)
        Core.Parser.Utils.tok_matchs(ct, "KEYWORD", "lambda") ->
            lambda_expr(state)
        True ->
            state = Core.Parser.Utils.set_error(
                state,
                Elixir.Enum.join([
                    "Expected int, float, identifier, '+', '-', '(', '[', if, def, lambda or case. ",
                    "Received: ",
                    ct_type
                ]),
                Elixir.Map.get(ct, "pos_start"),
                Elixir.Map.get(ct, "pos_end")
            )
            [state, None]


def loop_while(st, while_func, do_func):
    ct = Elixir.Map.get(st, "current_tok")

    valid = while_func(st, ct)

    case valid:
        True -> do_func(st, ct) |> loop_while(while_func, do_func)
        False -> st

def bin_op(state, func_a, ops, func_b):
    func_b = func_b if func_b != None else func_a

    [state, first_left] = func_a(state)

    ct = Elixir.Map.get(state, "current_tok")

    state = loop_while(
        state,
        lambda state, ct:
            case:
                Elixir.Map.get(ct, "type") == "EOF" -> False
                Elixir.Map.get(state, "error") != None -> False
                Elixir.Enum.member?(ops, Elixir.Map.get(ct, "type")) or Elixir.Enum.member?(ops, [Elixir.Map.get(ct, "type"), Elixir.Map.get(ct, "value")]) -> True
                True -> False
        ,
        lambda state, ct:
            left = Elixir.Map.get(state, "_node", first_left)
            state = Elixir.Map.delete(state, "_node")

            op_tok = Elixir.Map.get(state, 'current_tok')
            state = advance(state)

            [state, right] = func_b(state)

            case Elixir.Map.get(state, "error"):
                None ->
                    left = Core.Parser.Nodes.make_bin_op_node(left, op_tok, right)
                    Elixir.Map.put(state, "_node", left)
                _ -> state
    )

    left = Elixir.Map.get(state, '_node', first_left)
    state = Elixir.Map.delete(state, '_node')

    [state, left]

def list_expr(state):
    pos_start = Elixir.Map.get(state, "current_tok") |> Elixir.Map.get("pos_start")

    state = loop_while(
        state,
        lambda state, ct:
            case:
                Elixir.Map.get(ct, "type") == "RSQUARE" -> False
                Elixir.Map.get(ct, "type") == "EOF" -> False
                Elixir.Map.get(state, "error") != None -> False
                True -> True
        ,
        lambda state, ct:
            element_nodes = Elixir.Map.get(state, "_element_nodes", [])
            state = Elixir.Map.delete(state, "_element_nodes")

            state = state if Elixir.Map.get(ct, "type") == "COMMA" and element_nodes == [] else advance(state)

            case Elixir.Map.get(state, "current_tok") |> Elixir.Map.get("type"):
                "RSQUARE" -> state
                _ ->
                    [state, _expr] = expr(state)

                    Elixir.Map.put(
                        state |> Elixir.Map.put("_element_nodes", element_nodes),
                        "_element_nodes",
                        Elixir.List.flatten([element_nodes, _expr])
                    )
    )

    ct = Elixir.Map.get(state, "current_tok")

    case Elixir.Map.get(ct, 'type'):
        'RSQUARE' ->
            element_nodes = Elixir.Map.get(state, "_element_nodes", [])
            state = Elixir.Map.delete(state, "_element_nodes")

            pos_end = Elixir.Map.get(state, "current_tok") |> Elixir.Map.get("pos_end")

            node = Core.Parser.Nodes.make_list_node(element_nodes, pos_start, pos_end)

            state = advance(state)

            [state, node]
        _ ->
            state = Core.Parser.Utils.set_error(
                state,
                "Expected ']'",
                Elixir.Map.get(ct, "pos_start"),
                Elixir.Map.get(ct, "pos_end")
            )
            [state, None]


def map_expr(state):
    pos_start = Elixir.Map.get(state, "current_tok") |> Elixir.Map.get("pos_start")

    map_get_pairs = lambda state:
        [state, key] = expr(state)

        case:
            (Elixir.Map.get(state, "current_tok") |> Elixir.Map.get("type")) == "DO" ->
                state = advance(state)

                [state, value] = expr(state)

                [state, {key: value}]
            True ->
                ct = Elixir.Map.get(state, "current_tok")
                Core.Parser.Utils.set_error(
                    state,
                    "Empty staments are not allowed",
                    Elixir.Map.get(ct, "pos_start"),
                    Elixir.Map.get(ct, "pos_end")
                )
                [state, None]

    state = loop_while(
        state,
        lambda state, ct:
            case:
                Elixir.Map.get(ct, "type") == "RCURLY" -> False
                Elixir.Map.get(ct, "type") == "EOF" -> False
                Elixir.Map.get(state, "error") != None -> False
                True -> True
        ,
        lambda state, ct:
            pairs = Elixir.Map.get(state, "_pairs", {})
            state = Elixir.Map.delete(state, "_pairs")

            state = advance(state)

            case Elixir.Map.get(state, "current_tok") |> Elixir.Map.get("type"):
                "RCURLY" -> state
                _ ->
                    [state, map] = map_get_pairs(state)

                    case map:
                        None -> state
                        _ -> Elixir.Map.put(state, "_pairs", Elixir.Map.merge(pairs, map))
    )

    ct = Elixir.Map.get(state, "current_tok")

    case Elixir.Map.get(ct, 'type'):
        'RCURLY' ->
            pairs = Elixir.Map.get(state, "_pairs", {})
                |> Elixir.Map.to_list()
                |> Elixir.Enum.map(lambda i: [Elixir.Kernel.elem(i, 0), Elixir.Kernel.elem(i, 1)])

            pos_end = Elixir.Map.get(state, "current_tok") |> Elixir.Map.get("pos_end")

            node = Core.Parser.Nodes.make_map_node(pairs, pos_start, pos_end)

            state = state |> Elixir.Map.delete("_pairs") |> Elixir.Map.delete("_break") |> advance()

            [state, node]
        _ ->
            state = Core.Parser.Utils.set_error(
                state,
                "Expected '}'",
                Elixir.Map.get(ct, "pos_start"),
                Elixir.Map.get(ct, "pos_end")
            )
            [state, None]


def if_expr(state, expr_for_true):
    state = advance(state)

    [state, condition] = expr(state)

    case Core.Parser.Utils.tok_matchs(Elixir.Map.get(state, "current_tok"), "KEYWORD", "else"):
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
                Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_start"),
                Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
            )

            [state, None]


def pipe_expr(state, left_node):
    state = advance(state)

    [state, right_node] = expr(state)

    case Elixir.Map.get(state, 'error'):
        None ->
            node = Core.Parser.Nodes.make_pipe_node(left_node, right_node)
            [state, node]
        _ ->
            state = Core.Parser.Utils.set_error(
                state,
                "Expected and expression after '|>'",
                Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_start"),
                Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
            )

            [state, None]

def func_as_var_expr(state):
    pos_start = Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('pos_start')
    state = advance(state)

    sequence = [
        state |> Elixir.Map.get('current_tok') |> Elixir.Map.get('type'),
        state |> advance() |> Elixir.Map.get('current_tok') |> Elixir.Map.get('type'),
        state |> advance() |> advance() |> Elixir.Map.get('current_tok') |> Elixir.Map.get('type')
    ]

    case sequence:
        ["IDENTIFIER", "DIV", "INT"] ->
            var_name_tok = Elixir.Map.get(state, 'current_tok')

            state = advance(state)
            state = advance(state)

            arity = Elixir.Map.get(state, 'current_tok')
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
                Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_start"),
                Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
            )
            [state, None]
        ['IDENTIFIER', "DIV", _] ->
            state = state |> advance() |> advance()
            state = Core.Parser.Utils.set_error(
                state,
                "Expected arity number as int",
                Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_start"),
                Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
            )
            [state, None]
        [_, _, _] ->
            state = Core.Parser.Utils.set_error(
                state,
                "Expected the function name and arity. E.g: &sum/2",
                Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_start"),
                Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
            )
            [state, None]


def case_expr(state):
    pos_start = Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('pos_start')
    initial_ident = Elixir.Map.get(state, "current_tok") |> Elixir.Map.get('ident')

    state = advance(state)

    is_cond = (Elixir.Map.get(state, "current_tok") |> Elixir.Map.get("type")) == "DO"

    [state, _expr] = case is_cond:
        True -> [state, None]
        False -> expr(state)

    do_line = pos_start |> Elixir.Map.get('ln')
    state = advance(state)

    check_ident = lambda state:
        case (Elixir.Map.get(state, "current_tok") |> Elixir.Map.get('ident')) <= initial_ident:
            True ->
                Core.Parser.Utils.set_error(
                    state,
                    "The expresions of case must be idented 4 spaces forward in reference to 'case' keyword",
                    Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_start"),
                    Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
                )
            False -> state

    state = case (Elixir.Map.get(state, "current_tok") |> Elixir.Map.get("pos_start") |> Elixir.Map.get('ln')) > do_line:
        True ->
            loop_while(
                state,
                lambda state, ct:
                    case:
                        Elixir.Map.get(ct, "type") == "EOF" -> False
                        Elixir.Map.get(state, "error") != None -> False
                        Elixir.Map.get(ct, "ident") != initial_ident + 4 -> False
                        True -> True
                ,
                lambda state, ct:
                    state = check_ident(state)

                    cases = Elixir.Map.get(state, "_cases", [])
                    state = Elixir.Map.delete(state, "_cases")

                    this_ident = Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('ident')

                    [state, left_expr] = expr(state)

                    case (Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('type')) == 'ARROW':
                        True ->
                            state = advance(state)

                            [state, right_expr] = case (Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('ident')) == this_ident:
                                True -> statement(state)
                                False -> statements(state, this_ident + 4)

                            cases = Elixir.List.insert_at(cases, -1, [left_expr, right_expr])

                            state |> Elixir.Map.put('_cases', cases)
                        False ->
                            Core.Parser.Utils.set_error(
                                state,
                                "Expected '->'",
                                Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_start"),
                                Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
                            )
            )
        False ->
            Core.Parser.Utils.set_error(
                state,
                "Expected new line after ':'",
                Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_start"),
                Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
            )

    cases = Elixir.Map.get(state, '_cases', [])

    case cases:
        [] ->
            state = Core.Parser.Utils.set_error(
                state,
                "Case must have at least one case",
                Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_start"),
                Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
            )
            [state, None]
        _ ->
            state = Elixir.Map.delete(state, '_cases')

            node = Core.Parser.Nodes.make_case_node(
                _expr, cases, pos_start, Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('pos_start')
            )

            [state, node]


def func_def_expr(state):
    state = case (Elixir.Map.get(state, "current_tok") |> Elixir.Map.get('ident')) != 0:
        True -> Core.Parser.Utils.set_error(
            state,
            "'def' is only allowed in modules scope. TO define functions inside functions use 'lambda' instead.",
            Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_start"),
            Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
        )
        False -> state

    pos_start = Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('pos_start')
    def_token_ln = pos_start |> Elixir.Map.get('ln')

    state = advance(state)

    state = case (Elixir.Map.get(state, "current_tok") |> Elixir.Map.get('type')) != 'IDENTIFIER':
        True -> Core.Parser.Utils.set_error(
            state,
            "Expected a identifier after 'def'.",
            Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_start"),
            Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
        )
        False -> state

    var_name_tok = Elixir.Map.get(state, 'current_tok')

    state = advance(state)

    state = case (Elixir.Map.get(state, "current_tok") |> Elixir.Map.get('type')) != 'LPAREN':
        True -> Core.Parser.Utils.set_error(
            state,
            "Expected '('",
            Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_start"),
            Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
        )
        False -> state

    state = advance(state)

    [state, arg_name_toks] = resolve_params(state, "RPAREN")

    state = advance(state)

    state = case (Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('type')) == 'DO':
        True -> advance(state)
        False -> Core.Parser.Utils.set_error(
            state,
            "Expected ':'",
            Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_start"),
            Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
        )

    state = case (Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('pos_start') |> Elixir.Map.get('ln')) > def_token_ln:
        True -> state
        False -> Core.Parser.Utils.set_error(
            state,
            "Expected a new line after ':'",
            Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_start"),
            Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
        )

    # Here we check if a doc string exists
    # but we only consider the MULLINESTRING Token as a docstring
    # if there's any other statements in the function
    # otherwise this token is just the return of the function

    ct_type = state["current_tok"]['type']

    (state, docstring) = case ct_type == 'MULLINESTRING' and advance(state)['current_tok']['ident'] > def_token_ln:
        True -> (advance(state), Map.get(state, "current_tok"))
        False -> (state, None)

    # evaluates body of function
    [state, body] = statements(state, 4)

    case [arg_name_toks, body]:
        [_, None] ->    [state, None]
        [None, _] ->    [state, None]
        [None, None] -> [state, None]
        _ ->
            node = Core.Parser.Nodes.make_funcdef_node(
                var_name_tok, arg_name_toks, body, pos_start
            )

            [state, node]


def resolve_params(state, end_tok):
    state = loop_while(
        state,
        lambda state, ct:
            case:
                Elixir.Map.get(ct, "type") == "EOF" -> False
                Elixir.Map.get(ct, "type") == end_tok -> False
                Elixir.Map.get(state, "error") != None -> False
                True -> True
        ,
        lambda state, ct:
            arg_name_toks = Elixir.Map.get(state, '_arg_name_toks', [])
            state = Elixir.Map.delete(state, "_arg_name_toks")

            case Elixir.Map.get(ct, 'type') == 'IDENTIFIER':
                True ->
                    arg_name_toks = Elixir.List.insert_at(arg_name_toks, -1, ct)

                    state = advance(state)

                    ct_type = Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('type')

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
                                Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_start"),
                                Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
                            )

                False -> Core.Parser.Utils.set_error(
                    state,
                    "Expected identifier",
                    Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_start"),
                    Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
                )
    )

    arg_name_toks = Elixir.Map.get(state, '_arg_name_toks', [])

    case (Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('type')) == end_tok:
        True ->
            [state |> Elixir.Map.delete('_arg_name_toks'), arg_name_toks]
        False ->
            state = Core.Parser.Utils.set_error(
                state,
                Elixir.Enum.join(["Expected ", "':'" if end_tok == 'DO' else "')'"]),
                Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_start"),
                Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
            )

            state = state |> Elixir.Map.delete('_arg_name_toks')
            [state, None]

def is_keyword(state):
    (Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('type')) == 'IDENTIFIER' and (Elixir.Map.get(advance(state), 'current_tok') |> Elixir.Map.get('type')) == 'EQ'

def call_func_expr(state, atom):
    pos_start = Elixir.Map.get(state, 'pos_start')

    state = advance(state)

    state = case (Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('type')) == 'RPAREN':
        True ->
            state |> Elixir.Map.put('_arg_nodes', []) |> Elixir.Map.put('_keywords', {})
        False ->
            loop_while(
                state,
                lambda state, ct:
                    case:
                        Elixir.Map.get(ct, "type") == "EOF" -> False
                        Elixir.Map.get(ct, "type") == "RPAREN" -> False
                        Elixir.Map.get(state, "error") != None -> False
                        True -> True
                ,
                lambda state, ct:
                    arg_nodes = Elixir.Map.get(state, '_arg_nodes', [])
                    keywords = Elixir.Map.get(state, '_keywords', {})

                    state = Elixir.Map.delete(state, '_arg_nodes') |> Elixir.Map.delete('_keywords')

                    case:
                        not is_keyword(state) and keywords != {} ->
                            Core.Parser.Utils.set_error(
                                state,
                                "Non keyword arguments must be placed before any keyword argument",
                                Elixir.Map.get(state, Elixir.Map.get('current_tok'), "pos_start"),
                                Elixir.Map.get(state, Elixir.Map.get('current_tok'), "pos_end")
                            )
                        True ->
                            updated_fields = case is_keyword(state):
                                True ->
                                    _key = Elixir.Map.get(state, 'current_tok')
                                    key_value = _key |> Elixir.Map.get('value')

                                    state = state |> advance() |> advance()

                                    state = case Elixir.Map.has_key?(keywords, key_value):
                                        True ->
                                            Core.Parser.Utils.set_error(
                                                state,
                                                "Duplicated keyword",
                                                Elixir.Map.get(_key, "pos_start"),
                                                Elixir.Map.get(Elixir.Map.get(state, 'current_tok'), "pos_start")
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

                            case Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('type'):
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
                                        Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_start"),
                                        Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
                                    )
            )

    arg_nodes = Elixir.Map.get(state, '_arg_nodes')
    keywords = Elixir.Map.get(state, '_keywords')

    state = state |> Elixir.Map.delete('_arg_nodes') |> Elixir.Map.delete('_keywords')

    state = case (Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('type')) == 'RPAREN':
        True -> state
        False -> Core.Parser.Utils.set_error(
            state,
            "Expected ')'",
            Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_start"),
            Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
        )

    case Elixir.Map.get(state, 'error'):
        None ->
            pos_end = Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('pos_end')

            state = advance(state)

            node = Core.Parser.Nodes.make_call_node(atom, arg_nodes, keywords, pos_end)

            [state, node]
        _ ->
            [state, None]

def lambda_expr(state):
    pos_start = Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('pos_start')
    lambda_token_ln = pos_start |> Elixir.Map.get('ln')
    lambda_token_ident = Elixir.Map.get(state, "current_tok") |> Elixir.Map.get('ident')

    state = advance(state)

    [state, arg_name_toks] = resolve_params(state, 'DO')

    state = case (Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('type')) == 'DO':
        True -> advance(state)
        False -> Core.Parser.Utils.set_error(
            state,
            "Expected ':'",
            Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_start"),
            Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
        )


    [state, body] = case (Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('pos_start') |> Elixir.Map.get('ln')) == lambda_token_ln:
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
                Elixir.Map.get(ct, "type") == "EOF" -> False
                Elixir.Map.get(ct, "type") == "RPAREN" -> False
                Elixir.Map.get(state, "error") != None -> False
                True -> True
        ,
        lambda state, ct:
            exprs = Elixir.Map.get(state, '_element_nodes', [])
            state = Elixir.Map.delete(state, '_element_nodes')

            [state, _expr] = expr(state)

            exprs = Elixir.List.insert_at(exprs, -1, _expr)

            case Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('type'):
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
                        Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_start"),
                        Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
                    )
    )

    element_nodes = case first_expr:
        None -> []
        _ ->
            state
                |> Elixir.Map.get('_element_nodes', [])
                |> Elixir.List.insert_at(0, first_expr)

    state = state |> Elixir.Map.delete('_element_nodes')

    state = case (Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('type')) == 'RPAREN':
        True -> state
        False -> Core.Parser.Utils.set_error(
            state,
            "Expected ')'",
            Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_start"),
            Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
        )

    case Elixir.Map.get(state, 'error'):
        None ->
            pos_end = Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('pos_end')

            state = advance(state)

            node = Core.Parser.Nodes.make_tuple_node(element_nodes, pos_start, pos_end)

            [state, node]
        _ ->
            [state, None]

def pattern_match(state, left_node, pos_start):
    state = advance(state)

    valid_left_node = Elixir.Kernel.is_map(left_node) and Elixir.Map.get(left_node, "NodeType") in Core.Parser.Nodes.node_types_accept_pattern()

    case:
        Elixir.Map.get(state, 'error') -> [state, None]
        valid_left_node == False ->
            state = Core.Parser.Utils.set_error(
                state,
                "Invalid pattern",
                pos_start,
                Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
            )
            [state, None]
        valid_left_node == True ->
            [state, right_node] = expr(state)

            pos_end = Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('pos_start')

            node = Core.Parser.Nodes.make_patternmatch_node(
                left_node, right_node, pos_start, pos_end
            )

            [state, node]

def static_access_expr(state, left_node):
    state = advance(state)

    [state, node_value] = expr(state)

    state = case Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('type'):
        'RSQUARE' -> state
        _ ->
            Core.Parser.Utils.set_error(
                state,
                "Expected ]",
                Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_start"),
                Elixir.Map.get(Elixir.Map.get(state, "current_tok"), "pos_end")
            )

    case Elixir.Map.get(state, 'error'):
        None ->
            pos_end = Elixir.Map.get(state, 'current_tok') |> Elixir.Map.get('pos_end')
            node = Core.Parser.Nodes.make_staticaccess_node(left_node, node_value, pos_end)

            state = advance(state)

            [state, node]
        _ -> [state, None]
