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
    case node:
        None -> node
        _ -> new_resolver(node, var_names_avaliable)

def node_accept_pattern_match((node_type, _, _)):
    node_type in Core.Parser.Nodes.node_types_accept_pattern()

def get_variables_bound_in_pattern((:map, _, pairs)):
    # We dont support pattern match on map keys
    Elixir.Enum.map(
        pairs,
        lambda (_, value): get_variables_bound_in_pattern(value)
    )

def get_variables_bound_in_pattern((:tuple, _, elements)):
    elements
        |> Elixir.Enum.filter(&node_accept_pattern_match/1)
        |> Elixir.Enum.map(&get_variables_bound_in_pattern/1)

def get_variables_bound_in_pattern((:list, _, elements)):
    elements
        |> Elixir.Enum.filter(&node_accept_pattern_match/1)
        |> Elixir.Enum.map(&get_variables_bound_in_pattern/1)

def get_variables_bound_in_pattern((:var, _, [_, value])):
    value

def get_variables_bound_in_pattern((node_type, _, _)):
    raise Elixir.Enum.join([
        "The node type '", node_type, "' doesnt work as a pattern match"
    ])

def new_resolver(node <- (:call, meta, [node_to_call, args, keywords, _]), var_names_avaliable):
    local_call = case node_to_call:
        (:var, _, [_pinned, func_name]) ->
            not Elixir.String.contains?(func_name, ".") and func_name in var_names_avaliable
        (:call, _, _) -> True
        (:static_access, _, _) -> True
        True -> False

    node_to_call = convert_local_function_calls(node_to_call, var_names_avaliable)
    args = Elixir.Enum.map(
        args, lambda i: convert_local_function_calls(i, var_names_avaliable)
    )
    keywords = Elixir.Enum.map(
        keywords,
        lambda (key, value):
            (key, convert_local_function_calls(value, var_names_avaliable))
    )

    (:call, meta, [node_to_call, args, keywords, local_call])

def new_resolver(node <- (:number, _, _), _):
    node

def new_resolver(node <- (:atom, _, _), _):
    node

def new_resolver(node <- (:var, _, _), _):
    node

def new_resolver(node <- (:string, _, _), _):
    node

def new_resolver(node <- (:func, _, _), _):
    node

def new_resolver((:unary, meta, [op, op_node]), var_names_avaliable):
    (:unary, meta, [op, convert_local_function_calls(op_node, var_names_avaliable)])

def new_resolver((:list, meta, elements), var_names_avaliable):
    (
        :list,
        meta,
        Elixir.Enum.map(elements, lambda i: convert_local_function_calls(i, var_names_avaliable))
    )

def new_resolver((:tuple, meta, elements), var_names_avaliable):
    (
        :tuple,
        meta,
        Elixir.Enum.map(elements, lambda i: convert_local_function_calls(i, var_names_avaliable))
    )

def new_resolver((:binop, meta, [left, op, right]), var_names_avaliable):
    (
        :binop,
        meta,
        [
            convert_local_function_calls(left, var_names_avaliable),
            op,
            convert_local_function_calls(right, var_names_avaliable)
        ]
    )

def new_resolver((:pattern, meta, [left, right]), var_names_avaliable):
    (
        :pattern,
        meta,
        [
            left,
            convert_local_function_calls(right, var_names_avaliable)
        ]
    )

def new_resolver((:if, meta, [comp_expr, true_case, false_case]), var_names_avaliable):
    (
        :if,
        meta,
        [
            convert_local_function_calls(comp_expr, var_names_avaliable),
            convert_local_function_calls(true_case, var_names_avaliable),
            convert_local_function_calls(false_case, var_names_avaliable)
        ]
    )

def new_resolver((:statements, meta, nodes), var_names_avaliable):
    defined_vars_this_level = nodes
        |> Elixir.Enum.filter(lambda (node_type, _, _): node_type == :pattern)
        |> Elixir.Enum.map(lambda (_, _, [left_node, _]):
            # only the left node can assign any variable
            get_variables_bound_in_pattern(left_node)
        )

    var_names_avaliable = Elixir.List.flatten([var_names_avaliable, defined_vars_this_level])

    (
        :statements,
        meta,
        Elixir.Enum.map(nodes, lambda i:
            convert_local_function_calls(i, var_names_avaliable)
        )
    )


def new_resolver((:def, meta, [name, args, statements]), var_names_avaliable):
    [args, statements] = get_vars_defined_def_or_lambda(
        args, statements, var_names_avaliable
    )

    (:def, meta, [name, args, statements])

def new_resolver((:lambda, meta, [args, statements]), var_names_avaliable):
    (:lambda, meta, get_vars_defined_def_or_lambda(args, statements, var_names_avaliable))

def new_resolver((:static_access, meta, [node_to_access, node_key]), var_names_avaliable):
    (
        :static_access,
        meta,
        [
            convert_local_function_calls(node_to_access, var_names_avaliable),
            convert_local_function_calls(node_key, var_names_avaliable)
        ]
    )

def new_resolver((:raise, meta, [expr]), var_names_avaliable):
    (:raise, meta, [convert_local_function_calls(expr, var_names_avaliable)])

def new_resolver((:pipe, meta, [left_node, right_node]), var_names_avaliable):
    (
        :pipe,
        meta,
        [
            convert_local_function_calls(left_node, var_names_avaliable),
            convert_local_function_calls(right_node, var_names_avaliable)
        ]
    )

def new_resolver((:map, meta, pairs), var_names_avaliable):
    (
        :map,
        meta,
        Elixir.Enum.map(pairs, lambda i: resolve_map_pair(i, var_names_avaliable))
    )

def new_resolver((:case, meta, [expr, pairs]), var_names_avaliable):
    # When expr of case is none we convert to a elixir Cond node
    expr = convert_local_function_calls(expr, var_names_avaliable) if expr != None else None

    # only elixir's Cond can have function call in the case expr
    pairs = Elixir.Enum.map(
        pairs,
        lambda (left, right):
            (
                convert_local_function_calls(left, var_names_avaliable) if expr != None else left,
                convert_local_function_calls(right, var_names_avaliable)
            )
    )

    (:case, meta, [expr, pairs])

def new_resolver((:try, meta, [try_block, exceptions, finally_block]), var_names_avaliable):
    try_block = convert_local_function_calls(try_block, var_names_avaliable)
    exceptions = Elixir.Enum.map(
        exceptions,
        lambda (except_identifier, alias, block):
            (except_identifier, alias, convert_local_function_calls(block, var_names_avaliable))
    )
    finally_block = convert_local_function_calls(finally_block, var_names_avaliable)

    (:try, meta, [try_block, exceptions, finally_block])

def new_resolver((:unpack, meta, [node_to_unpack]), var_names_avaliable):
    (
        :unpack, meta, [new_resolver(node_to_unpack, var_names_avaliable)]
    )

def new_resolver(node <- (:range, meta, [left_node, right_node]), var_names_avaliable):
    (
        :range,
        meta,
        [
            new_resolver(left_node, var_names_avaliable),
            new_resolver(right_node, var_names_avaliable),
        ]
    )

def resolve_map_pair((key, value), var_names_avaliable):
    (
        convert_local_function_calls(key, var_names_avaliable),
        convert_local_function_calls(value, var_names_avaliable)
    )

def resolve_map_pair((:spread, meta, [node_to_spread]), var_names_avaliable):
    (
        :spread, meta, [new_resolver(node_to_spread, var_names_avaliable)]
    )


def get_vars_defined_def_or_lambda(args, statements,var_names_avaliable):
    received_arguments = args
        |> Elixir.Enum.filter(lambda (node_type, _, _):
            node_type in Core.Parser.Nodes.node_types_accept_pattern()
        )
        |> Elixir.Enum.map(&get_variables_bound_in_pattern/1)

    statements = convert_local_function_calls(
        statements,
        Elixir.List.flatten(var_names_avaliable, received_arguments)
    )

    [args, statements]