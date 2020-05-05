def convert_local_function_calls(node, var_names_avaliable):
    # Main function

    # Simple job:
    # We dont want to, like elixer does, need to call local defined functions
    # (or funcs received as params) using a dot before parenteses. E.g:
    # add.(1, 2)

    # Solution: set "local_call" of all CallNodes to true if they are referencing
    # some variable defined previously or if the variable was received as argument
    # for the current function

    # Only the StatementsNode can have a VarAssignNode
    # and only the matched nodes bellow have a StatementsNode inside

    # The func_def and lambda are special cases because it
    # can have a function being received by param.
    # Except for the name, both are equal so we can use the same function

    case Map.get(node, 'NodeType'):
        'StatementsNode' -> resolve_statements(node, var_names_avaliable)
        'FuncDefNode' -> resolve_func_def(node, var_names_avaliable)
        'LambdaNode' -> resolve_func_def(node, var_names_avaliable)
        'CallNode' -> resolve_call_node(node, var_names_avaliable)
        'CaseNode' -> resolve_case_node(node, var_names_avaliable)
        _ -> node


def resolve_statements(node, var_names_avaliable):
    defined_vars_this_level = Map.get(node, 'statement_nodes')
        |> Enum.filter(lambda i:
            Map.get(i, 'NodeType') == 'VarAssignNode'
        )
        |> Enum.map(lambda i:
            Map.get(i, 'var_name_tok') |> Map.get('value')
        )

    var_names_avaliable = List.flatten([var_names_avaliable, defined_vars_this_level])

    statement_nodes = Map.get(node, "statement_nodes")
        |> Enum.map(lambda i:
            convert_local_function_calls(i, var_names_avaliable)
        )

    node |> Map.put('statement_nodes', statement_nodes)


def resolve_func_def(func_def_node, var_names_avaliable):
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

    Map.put(node, 'local_call', func_name in var_names_avaliable)


def resolve_case_node(node, var_names_avaliable):
    cases = Map.get(node, 'cases')
        |> Enum.map(lambda i:
            condition = Enum.at(i, 0)
            statements = Enum.at(i, 1)

            [condition, convert_local_function_calls(statements, var_names_avaliable)]
        )

    Map.put(node, 'cases', cases)
