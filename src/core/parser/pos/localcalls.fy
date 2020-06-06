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

    # TEMP FIX WHILE WE DONT CONVERT ALL NODES TO NEW AST
    case Elixir.Map.get(node, '_new') if Elixir.Kernel.is_map(node) else None:
        None ->
            case Elixir.Map.get(node, 'NodeType') if Elixir.Kernel.is_map(node) else None:
                'CallNode' -> resolve_call_node(node, var_names_avaliable)
                'CaseNode' -> resolve_case_node(node, var_names_avaliable)
                _ -> node
        _ ->
            new_resolver(node, var_names_avaliable)

def node_accept_pattern_match({"NodeType": node_type}):
    node_type in Core.Parser.Nodes.node_types_accept_pattern()

def get_variables_bound_in_pattern({"_new": (:map, _, pairs)}):
    # We dont support pattern match on map keys
    Elixir.Enum.map(
        pairs,
        lambda (_, value): get_variables_bound_in_pattern(value)
    )

def get_variables_bound_in_pattern({"_new": (:tuple, _, elements)}):
    elements
        |> Elixir.Enum.filter(&node_accept_pattern_match/1)
        |> Elixir.Enum.map(&get_variables_bound_in_pattern/1)

def get_variables_bound_in_pattern({"_new": (:list, _, elements)}):
    elements
        |> Elixir.Enum.filter(&node_accept_pattern_match/1)
        |> Elixir.Enum.map(&get_variables_bound_in_pattern/1)

def get_variables_bound_in_pattern({"_new": (:var, _, [_, value])}):
    value

def get_variables_bound_in_pattern({"NodeType": node_type}):
    raise Elixir.Enum.join([
        "The node type '", node_type, "' doesnt work as a pattern match"
    ])

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

def new_resolver(node <- {"_new": (:number, _, _)}, _):
    node

def new_resolver(node <- {"_new": (:atom, _, _)}, _):
    node

def new_resolver(node <- {"_new": (:var, _, _)}, _):
    node

def new_resolver(node <- {"_new": (:string, _, _)}, _):
    node

def new_resolver(node <- {"_new": (:func, _, _)}, _):
    node

def new_resolver(node <- {"_new": (:unary, meta, [op, op_node])}, var_names_avaliable):
    Elixir.Map.merge(
        node,
        {
            "_new": (:unary, meta, [op, convert_local_function_calls(op_node, var_names_avaliable)])
        }
    )

def new_resolver(node <- {"_new": (:list, meta, elements)}, var_names_avaliable):
    Elixir.Map.merge(
        node,
        {
            "_new": (
                :list,
                meta,
                Elixir.Enum.map(elements, lambda i: convert_local_function_calls(i, var_names_avaliable))
            )
        }
    )

def new_resolver(node <- {"_new": (:tuple, meta, elements)}, var_names_avaliable):
    Elixir.Map.merge(
        node,
        {
            "_new": (
                :tuple,
                meta,
                Elixir.Enum.map(elements, lambda i: convert_local_function_calls(i, var_names_avaliable))
            )
        }
    )

def new_resolver(node <- {"_new": (:binop, meta, [left, op, right])}, var_names_avaliable):
    Elixir.Map.merge(
        node,
        {
            "_new": (
                :binop,
                meta,
                [
                    convert_local_function_calls(left, var_names_avaliable),
                    op,
                    convert_local_function_calls(right, var_names_avaliable)
                ]
            )
        }
    )

def new_resolver(node <- {"_new": (:pattern, meta, [left, right])}, var_names_avaliable):
    Elixir.Map.merge(
        node,
        {
            "_new": (
                :pattern,
                meta,
                [
                    left,
                    convert_local_function_calls(right, var_names_avaliable)
                ]
            )
        }
    )

def new_resolver(node <- {"_new": (:if, meta, [comp_expr, true_case, false_case])}, var_names_avaliable):
    Elixir.Map.merge(
        node,
        {
            "_new": (
                :if,
                meta,
                [
                    convert_local_function_calls(comp_expr, var_names_avaliable),
                    convert_local_function_calls(true_case, var_names_avaliable),
                    convert_local_function_calls(false_case, var_names_avaliable)
                ]
            )
        }
    )

def new_resolver(node <- {"_new": (:statements, meta, nodes)}, var_names_avaliable):
    defined_vars_this_level = nodes
        |> Elixir.Enum.filter(lambda i: i['NodeType'] == "PatternMatchNode")
        |> Elixir.Enum.map(lambda {"_new": (_, _, [left_node, _])}:
            # only the left node can assign any variable
            get_variables_bound_in_pattern(left_node)
        )

    var_names_avaliable = Elixir.List.flatten([var_names_avaliable, defined_vars_this_level])

    Elixir.Map.merge(
        node,
        {
            "_new": (
                :statements,
                meta,
                Elixir.Enum.map(nodes, lambda i:
                    convert_local_function_calls(i, var_names_avaliable)
                )
            )
        }
    )

def get_vars_defined_def_or_lambda(args, statements,var_names_avaliable):
    received_arguments = args
        |> Elixir.Enum.filter(lambda i:
            case Elixir.Kernel.is_map(i):
                True -> None
                False -> raise 'popai'

            i['NodeType'] in Core.Parser.Nodes.node_types_accept_pattern()
        )
        |> Elixir.Enum.map(&get_variables_bound_in_pattern/1)

    statements = convert_local_function_calls(
        statements,
        Elixir.List.flatten(var_names_avaliable, received_arguments)
    )

    [args, statements]

def new_resolver(node <- {"_new": (:def, meta, [name, args, statements])}, var_names_avaliable):
    [args, statements] = get_vars_defined_def_or_lambda(
        args, statements, var_names_avaliable
    )

    Elixir.Map.merge(
        node,
        {"_new": (:def, meta, [name, args, statements])}
    )

def new_resolver(node <- {"_new": (:lambda, meta, [args, statements])}, var_names_avaliable):
    Elixir.Map.merge(
        node,
        {"_new": (:lambda, meta, get_vars_defined_def_or_lambda(args, statements, var_names_avaliable))}
    )

def new_resolver(node <- {"_new": (:static_access, meta, [node_to_access, node_key])}, var_names_avaliable):
    Elixir.Map.merge(
        node,
        {
            "_new": (
                :static_access,
                meta,
                [
                    convert_local_function_calls(node_to_access, var_names_avaliable),
                    convert_local_function_calls(node_key, var_names_avaliable)
                ]
            )
        }
    )

def new_resolver(node <- {"_new": (:raise, meta, [expr])}, var_names_avaliable):
    Elixir.Map.merge(
        node,
        {"_new": (:raise, meta, [convert_local_function_calls(expr, var_names_avaliable)])}
    )

def new_resolver(node <- {"_new": (:pipe, meta, [left_node, right_node])}, var_names_avaliable):
    Elixir.Map.merge(
        node,
        {
            "_new": (
                :pipe,
                meta,
                [
                    convert_local_function_calls(left_node, var_names_avaliable),
                    convert_local_function_calls(right_node, var_names_avaliable)
                ]
            )
        }
    )

def new_resolver(node <- {"_new": (:map, meta, pairs)}, var_names_avaliable):
    Elixir.Map.merge(
        node,
        {
            "_new": (
                :map,
                meta,
                Elixir.Enum.map(
                    pairs,
                    lambda (key, value):
                        (
                            convert_local_function_calls(key, var_names_avaliable),
                            convert_local_function_calls(value, var_names_avaliable)
                        )
                )
            )
        }
    )