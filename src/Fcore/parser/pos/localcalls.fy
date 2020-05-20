def convert_local_function_calls(node, var_names_avaliable):
    # Main function

    # Simple job:
    # We dont want to, like elixer does, need to call local defined functions
    # (or funcs received as params) using a dot before parenteses. E.g:
    # add.(1, 2)

    # Solution: set "local_call" of all CallNodes to true if they are referencing
    # some variable defined previously or if the variable was received as argument
    # for the current function

    # Only the StatementsNode can have a PatternMatchNode
    # and only the matched nodes bellow have a StatementsNode inside

    case None in var_names_avaliable:
        True -> raise "None should not be in the var names"
        False -> None

    case Elixir.Map.get(node, 'NodeType') if Elixir.Kernel.is_map(node) else None:
        'StatementsNode' -> resolve_statements(node, var_names_avaliable)
        'PatternMatchNode' -> resolve_pattern(node, var_names_avaliable)
        'FuncDefNode' -> resolve_func_or_lambda(node, var_names_avaliable)
        'LambdaNode' -> resolve_func_or_lambda(node, var_names_avaliable)
        'CallNode' -> resolve_call_node(node, var_names_avaliable)
        'CaseNode' -> resolve_case_node(node, var_names_avaliable)
        'IfNode' -> resolve_if_node(node, var_names_avaliable)
        'PipeNode' -> resolve_pipe_node(node, var_names_avaliable)
        'InNode' -> resolve_in_node(node, var_names_avaliable)
        'ListNode' -> resolve_list_or_tuple_node(node, var_names_avaliable)
        'MapNode' -> resolve_map_node(node, var_names_avaliable)
        'RaiseNode' -> resolve_raise_node(node, var_names_avaliable)
        'StaticAccessNode' -> resolve_staticaccess_node(node, var_names_avaliable)
        'UnaryOpNode' -> resolve_unary_node(node, var_names_avaliable)
        'BinOpNode' -> resolve_unary_node(node, var_names_avaliable)
        _ -> node


def get_variables_bound_in_pattern(node):
    node_type = Elixir.Map.get(node, 'NodeType')

    filter_types = lambda i: Elixir.Map.get(i, 'NodeType') in Fcore.Parser.Nodes.node_types_accept_pattern()

    case:
        node_type == 'MapNode' ->
            node
                |> Elixir.Map.get("pairs_list")
                |> Elixir.List.flatten()
                |> Elixir.Enum.filter(filter_types)
                |> Elixir.Enum.map(&get_variables_bound_in_pattern/1)
        node_type in ['TupleNode', 'ListNode'] ->
            node
                |> Elixir.Map.get('element_nodes')
                |> Elixir.Enum.filter(filter_types)
                |> Elixir.Enum.map(&get_variables_bound_in_pattern/1)
        "VarAccessNode" ->
            Elixir.Map.get(node, "var_name_tok") |> Elixir.Map.get("value")
        True ->
            raise Elixir.Enum.join([
                "The node type '", node_type, "' doesnt work as a pattern match"
            ])


def resolve_statements(node, var_names_avaliable):
    defined_vars_this_level = Elixir.Map.get(node, 'statement_nodes')
        |> Elixir.Enum.filter(lambda i:
            Elixir.Map.get(i, 'NodeType') == 'PatternMatchNode'
        )
        |> Elixir.Enum.map(lambda i:
            # only the left node can assign any variable
            get_variables_bound_in_pattern(Elixir.Map.get(i, 'left_node'))
        )
        |> Elixir.List.flatten()

    var_names_avaliable = Elixir.List.flatten([var_names_avaliable, defined_vars_this_level])

    statement_nodes = Elixir.Map.get(node, "statement_nodes")
        |> Elixir.Enum.map(lambda i:
            convert_local_function_calls(i, var_names_avaliable)
        )

    node |> Elixir.Map.put('statement_nodes', statement_nodes)


def resolve_pattern(node, var_names_avaliable):
    Elixir.Map.merge(
        node,
        {
            "right_node": convert_local_function_calls(
                Elixir.Map.get(node, "right_node"), var_names_avaliable
            )
        }
    )


def resolve_func_or_lambda(func_def_node, var_names_avaliable):
    func_arguments = func_def_node
        |> Elixir.Map.get('arg_name_toks')
        |> Elixir.Enum.map(lambda i:
            Elixir.Map.get(i, 'value')
        )

    body_node = Elixir.Map.get(func_def_node, 'body_node')
        |> convert_local_function_calls(
            Elixir.List.flatten(var_names_avaliable, func_arguments)
        )

    Elixir.Map.put(func_def_node, 'body_node', body_node)


def resolve_call_node(node, var_names_avaliable):
    local_call = case:
        (Elixir.Map.get(node, 'node_to_call') |> Elixir.Map.get('NodeType')) == 'VarAccessNode' ->
            func_name = Elixir.Map.get(node, 'node_to_call')
                |> Elixir.Map.get('var_name_tok')
                |> Elixir.Map.get('value')

            not Elixir.String.contains?(func_name, ".") and func_name in var_names_avaliable
        (Elixir.Map.get(node, 'node_to_call') |> Elixir.Map.get('NodeType')) == 'CallNode' -> True
        (Elixir.Map.get(node, 'node_to_call') |> Elixir.Map.get('NodeType')) == 'StaticAccessNode' -> True
        True -> False

    Elixir.Map.merge(
        node,
        {
            'node_to_call': convert_local_function_calls(
                Elixir.Map.get(node, 'node_to_call'), var_names_avaliable
            ),
            'local_call': local_call,
            "arg_nodes": Elixir.Enum.map(
                Elixir.Map.get(node, "arg_nodes"),
                lambda i: convert_local_function_calls(i, var_names_avaliable)
            ),
            "keywords": Elixir.Map.new(
                Elixir.Map.get(node, "keywords"),
                lambda i:
                    key = Elixir.Kernel.elem(i, 0)
                    value = Elixir.Kernel.elem(i, 1) |> convert_local_function_calls(var_names_avaliable)
                    Elixir.Map.to_list({key: value}) |> Elixir.Enum.at(0)
            )
        }
    )


def resolve_case_node(node, var_names_avaliable):
    Elixir.Map.merge(
        node,
        {
            'expr': convert_local_function_calls(Elixir.Map.get(node, 'expr'), var_names_avaliable),
            'cases': node
                |> Elixir.Map.get('cases')
                |> Elixir.Enum.map(lambda i:
                    [condition, statements] = i
                    [condition, convert_local_function_calls(statements, var_names_avaliable)]
                )
        }
    )

def resolve_if_node(node, var_names_avaliable):
    Elixir.Map.merge(
        node,
        {
            "comp_expr": convert_local_function_calls(
                Elixir.Map.get(node, "comp_expr"), var_names_avaliable
            ),
            "true_case": convert_local_function_calls(
                Elixir.Map.get(node, "true_case"), var_names_avaliable
            ),
            "false_case": convert_local_function_calls(
                Elixir.Map.get(node, "false_case"), var_names_avaliable
            )
        }
    )

def resolve_pipe_node(node, var_names_avaliable):
    Elixir.Map.merge(
        node,
        {
            "left_node": convert_local_function_calls(
                Elixir.Map.get(node, "left_node"), var_names_avaliable
            ),
            "right_node": convert_local_function_calls(
                Elixir.Map.get(node, "right_node"), var_names_avaliable
            )
        }
    )

def resolve_in_node(node, var_names_avaliable):
    Elixir.Map.merge(
        node,
        {
            "left_expr": convert_local_function_calls(
                Elixir.Map.get(node, "left_expr"), var_names_avaliable
            ),
            "right_expr": convert_local_function_calls(
                Elixir.Map.get(node, "right_expr"), var_names_avaliable
            )
        }
    )

def resolve_varassign_node(node, var_names_avaliable):
    Elixir.Map.merge(
        node,
        {
            "value_node": convert_local_function_calls(
                Elixir.Map.get(node, "value_node"), var_names_avaliable
            )
        }
    )

def resolve_list_or_tuple_node(node, var_names_avaliable):
    Elixir.Map.merge(
        node,
        {
            "element_nodes": Elixir.Map.get(node, "element_nodes")
                |> Elixir.Enum.map(lambda i: convert_local_function_calls(i, var_names_avaliable))
        }
    )

def resolve_map_node(node, var_names_avaliable):
    Elixir.Map.merge(
        node,
        {
            "pairs_list": Elixir.Map.get(node, "pairs_list")
                |> Elixir.Enum.map(lambda i:
                    [
                        convert_local_function_calls(Elixir.Enum.at(i, 0), var_names_avaliable),
                        convert_local_function_calls(Elixir.Enum.at(i, 1), var_names_avaliable)
                    ]
                )
        }
    )

def resolve_raise_node(node, var_names_avaliable):
    Elixir.Map.merge(
        node,
        {
            "expr": convert_local_function_calls(
                Elixir.Map.get(node, "expr"), var_names_avaliable
            )
        }
    )

def resolve_unary_node(node, var_names_avaliable):
    Elixir.Map.merge(
        node,
        {
            "node": convert_local_function_calls(
                Elixir.Map.get(node, "node"), var_names_avaliable
            )
        }
    )

def resolve_unary_node(node, var_names_avaliable):
    Elixir.Map.merge(
        node,
        {
            "left_node": convert_local_function_calls(
                Elixir.Map.get(node, "left_node"), var_names_avaliable
            ),
            "right_node": convert_local_function_calls(
                Elixir.Map.get(node, "right_node"), var_names_avaliable
            )
        }
    )

def resolve_staticaccess_node(node, var_names_avaliable):
    Elixir.Map.merge(
        node,
        {
            "node": convert_local_function_calls(
                Elixir.Map.get(node, "node"), var_names_avaliable
            ),
            "node_value": convert_local_function_calls(
                Elixir.Map.get(node, "node_value"), var_names_avaliable
            )
        }
    )