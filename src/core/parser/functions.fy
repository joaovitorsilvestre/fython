def advance(state):
    Core.Parser.advance(state)

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
            state["current_tok"]["pos_start"],
            state["current_tok"]["pos_end"]
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

    [state, arg_nodes] = resolve_params(state, "RPAREN")

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
    [state, body] = Core.Parser.statements(state, 4)

    case [arg_nodes, body]:
        [_, None] ->    [state, None]
        [None, _] ->    [state, None]
        [None, None] -> [state, None]
        _ ->
            node = Core.Parser.Nodes.make_funcdef_node(
                var_name_tok, arg_nodes, body, docstring, pos_start
            )

            [state, node]


def lambda_expr(state):
    pos_start = state['current_tok']['pos_start']
    lambda_token_ln = pos_start['ln']
    lambda_token_ident = state["current_tok"]['ident']

    state = advance(state)

    [state, arg_nodes] = resolve_params(state, 'DO')

    state = case (state['current_tok']['type']) == 'DO':
        True -> advance(state)
        False -> Core.Parser.Utils.set_error(
            state,
            "Expected ':'",
            state["current_tok"]["pos_start"],
            state["current_tok"]["pos_end"]
        )

    [state, body] = case (state['current_tok']['pos_start']['ln']) == lambda_token_ln:
        True -> Core.Parser.expr(state)
        False -> Core.Parser.statements(state, lambda_token_ident + 4)

    case [arg_nodes, body]:
        [_, None] ->    [state, None]
        [None, _] ->    [state, None]
        [None, None] -> [state, None]
        _ ->
            node = Core.Parser.Nodes.make_lambda_node(
                None, arg_nodes, body, pos_start
            )

            [state, node]

def resolve_params(state, end_tok):
    state = Core.Parser.loop_while(
        state,
        lambda state, ct:
            case:
                ct["type"] == "EOF" -> False
                ct["type"] == end_tok -> False
                state["error"] != None -> False
                True -> True
        ,
        lambda state, ct:
            arg_nodes = Elixir.Map.get(state, '_arg_nodes', [])
            state = Elixir.Map.delete(state, "_arg_nodes")

            (state, node) = resolve_one_param(state)

            arg_nodes = Elixir.List.insert_at(arg_nodes, -1, node)

            ct_type = state['current_tok']['type']

            case:
                ct_type == 'COMMA' ->
                    state = advance(state)
                    Elixir.Map.put(state, '_arg_nodes', arg_nodes)
                ct_type == end_tok ->
                    Elixir.Map.put(state, '_arg_nodes', arg_nodes)
                True ->
                    Core.Parser.Utils.set_error(
                        state,
                        Elixir.Enum.join(["Expected ',' or '", end_tok, "'"]),
                        state["current_tok"]["pos_start"],
                        state["current_tok"]["pos_end"]
                    )
    )

    arg_nodes = Elixir.Map.get(state, '_arg_nodes', [])

    case (state['current_tok']['type']) == end_tok:
        True ->
            [state |> Elixir.Map.delete('_arg_nodes'), arg_nodes]
        False ->
            state = Core.Parser.Utils.set_error(
                state,
                Elixir.Enum.join(["Expected ", "':'" if end_tok == 'DO' else "')'"]),
                state["current_tok"]["pos_start"],
                state["current_tok"]["pos_end"]
            )

            state = state |> Elixir.Map.delete('_arg_nodes')
            [state, None]


def resolve_one_param(state):
    pos_start = state['current_tok']['pos_start']

    [state, node] = Core.Parser.expr(state)

    case node['NodeType'] in Core.Parser.Nodes.node_types_accept_pattern_in_function_argument():
        True -> (state, node)
        False ->
            state = Core.Parser.Utils.set_error(
                state,
                "Expected a identifier, list, tuple or map pattern matching",
                pos_start,
                state["current_tok"]["pos_end"]
            )
            (state, node)
