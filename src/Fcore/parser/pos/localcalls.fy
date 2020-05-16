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

    case Map.get(node, 'NodeType') if is_map(node) else None:
        'StatementsNode' -> resolve_statements(node, var_names_avaliable)
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
        'UnaryOpNode' -> resolve_unary_node(node, var_names_avaliable)
        'BinOpNode' -> resolve_unary_node(node, var_names_avaliable)
        _ -> node


def get_variables_bound_in_pattern(node):
    node_type = Map.get(node, 'NodeType')

    filter_types = lambda i: Map.get(i, 'NodeType') in Fcore.Parser.Nodes.node_types_accept_pattern()

    case:
        node_type == 'MapNode' ->
            node
                |> Map.get("pairs_list")
                |> List.flatten()
                |> Enum.filter(filter_types)
                |> Enum.map(&get_variables_bound_in_pattern/1)
        node_type in ['TupleNode', 'ListNode'] ->
            node
                |> Map.get('element_nodes')
                |> Enum.filter(filter_types)
                |> Enum.map(&get_variables_bound_in_pattern/1)
        "VarAccessNode" ->
            Map.get(node, "var_name_tok") |> Map.get("value")
        True ->
            raise Enum.join([
                "The node type '", node_type, "' doesnt work as a pattern match"
            ])


def resolve_statements(node, var_names_avaliable):
    defined_vars_this_level = Map.get(node, 'statement_nodes')
        |> Enum.filter(lambda i:
            Map.get(i, 'NodeType') == 'PatternMatchNode'
        )
        |> Enum.map(lambda i:
            # only the left node can assign any variable
            get_variables_bound_in_pattern(Map.get(i, 'left_node'))
        )
        |> List.flatten()

    var_names_avaliable = List.flatten([var_names_avaliable, defined_vars_this_level])

    statement_nodes = Map.get(node, "statement_nodes")
        |> Enum.map(lambda i:
            convert_local_function_calls(i, var_names_avaliable)
        )

    node |> Map.put('statement_nodes', statement_nodes)


def resolve_func_or_lambda(func_def_node, var_names_avaliable):
    func_arguments = func_def_node
        |> Map.get('arg_name_toks')
        |> Enum.map(lambda i:
            Map.get(i, 'value')
        )

    body_node = Map.get(func_def_node, 'body_node')
        |> convert_local_function_calls(
            List.flatten(var_names_avaliable, func_arguments)
        )

    Map.put(func_def_node, 'body_node', body_node)


def resolve_call_node(node, var_names_avaliable):
    func_name = Map.get(node, 'node_to_call')
        |> Map.get('var_name_tok')
        |> Map.get('value')

    node
        |> Map.put('local_call', func_name in var_names_avaliable)
        |> Map.merge(
            {
                "arg_nodes": Enum.map(
                    Map.get(node, "arg_nodes"),
                    lambda i: convert_local_function_calls(i, var_names_avaliable)
                ),
                "keywords": Map.new(
                    Map.get(node, "keywords"),
                    lambda i:
                        key = elem(i, 0)
                        value = elem(i, 1) |> convert_local_function_calls(var_names_avaliable)
                        Map.to_list({key: value}) |> Enum.at(0)
                )
            }
        )


def resolve_case_node(node, var_names_avaliable):
    cases = Map.get(node, 'cases')
        |> Enum.map(lambda i:
            condition = Enum.at(i, 0)
            statements = Enum.at(i, 1)

            [condition, convert_local_function_calls(statements, var_names_avaliable)]
        )

    Map.put(node, 'cases', cases)

def resolve_if_node(node, var_names_avaliable):
    Map.merge(
        node,
        {
            "comp_expr": convert_local_function_calls(
                Map.get(node, "comp_expr"), var_names_avaliable
            ),
            "true_case": convert_local_function_calls(
                Map.get(node, "true_case"), var_names_avaliable
            ),
            "false_case": convert_local_function_calls(
                Map.get(node, "false_case"), var_names_avaliable
            )
        }
    )

def resolve_pipe_node(node, var_names_avaliable):
    Map.merge(
        node,
        {
            "left_node": convert_local_function_calls(
                Map.get(node, "left_node"), var_names_avaliable
            ),
            "right_node": convert_local_function_calls(
                Map.get(node, "right_node"), var_names_avaliable
            )
        }
    )

def resolve_in_node(node, var_names_avaliable):
    Map.merge(
        node,
        {
            "left_expr": convert_local_function_calls(
                Map.get(node, "left_expr"), var_names_avaliable
            ),
            "right_expr": convert_local_function_calls(
                Map.get(node, "right_expr"), var_names_avaliable
            )
        }
    )

def resolve_varassign_node(node, var_names_avaliable):
    Map.merge(
        node,
        {
            "value_node": convert_local_function_calls(
                Map.get(node, "value_node"), var_names_avaliable
            )
        }
    )

def resolve_list_or_tuple_node(node, var_names_avaliable):
    Map.merge(
        node,
        {
            "element_nodes": Map.get(node, "element_nodes")
                |> Enum.map(lambda i: convert_local_function_calls(i, var_names_avaliable))
        }
    )

def resolve_map_node(node, var_names_avaliable):
    Map.merge(
        node,
        {
            "pairs_list": Map.get(node, "pairs_list")
                |> Enum.map(lambda i:
                    [
                        convert_local_function_calls(Enum.at(i, 0), var_names_avaliable),
                        convert_local_function_calls(Enum.at(i, 1), var_names_avaliable)
                    ]
                )
        }
    )

def resolve_raise_node(node, var_names_avaliable):
    Map.merge(
        node,
        {
            "expr": convert_local_function_calls(
                Map.get(node, "expr"), var_names_avaliable
            )
        }
    )

def resolve_unary_node(node, var_names_avaliable):
    Map.merge(
        node,
        {
            "node": convert_local_function_calls(
                Map.get(node, "node"), var_names_avaliable
            )
        }
    )

def resolve_unary_node(node, var_names_avaliable):
    Map.merge(
        node,
        {
            "left_node": convert_local_function_calls(
                Map.get(node, "left_node"), var_names_avaliable
            ),
            "right_node": convert_local_function_calls(
                Map.get(node, "right_node"), var_names_avaliable
            )
        }
    )
