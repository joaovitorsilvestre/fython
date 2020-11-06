def node_types_accept_pattern():
    [:list, :map, :tuple, :var]

def node_types_accept_pattern_in_function_argument():
    Elixir.List.flatten(
        node_types_accept_pattern(),
        [:number, :string, :atom]
    )

def gen_meta(file, pos_start, pos_end):
    convert_pos = lambda pos:
        # TODO Temp fix while pos of lexer doesnt follow new ast
        case Elixir.Kernel.is_map(pos):
            True ->
                {"idx": idx, "ln": ln, "col": col} = pos
                (idx, ln, col)
            False -> pos

    {"file": file, "start": convert_pos(pos_start), "end": convert_pos(pos_end)}

def make_number_node(file, tok):
    (
        :number,
        gen_meta(file, tok['pos_start'], tok['pos_end']),
        [tok['value']]
    )

def make_range_node(file, left_node, right_node, pos_start, pos_end):
    (
        :range,
        gen_meta(file, pos_start, pos_end),
        [left_node, right_node]
    )

def make_string_node(file, tok):
    (
        :string,
        gen_meta(file, tok['pos_start'], tok['pos_end']),
        [tok['value']]
    )

def make_varaccess_node(file, var_name_tok, pinned):
    (
        :var,
        gen_meta(file, var_name_tok['pos_start'], var_name_tok['pos_end']),
        [pinned, var_name_tok['value']]
    )

def make_staticaccess_node(file, node_left, node_value, pos_end):
    (_, {"start": pos_start}, _) = node_left

    (
        :static_access,
        gen_meta(file, pos_start, pos_end),
        [node_left, node_value]
    )

def make_if_node(file, comp_expr, true_expr, false_expr):
    (_, {"start": pos_start}, _) = comp_expr
    (_, {"end": pos_end}, _) = false_expr

    (
        :if,
        gen_meta(file, pos_start, pos_end),
        [comp_expr, true_expr, false_expr]
    )

def make_funcasvariable_node(file, var_name_tok, arity, pos_start):
    (
        :func,
        gen_meta(file, pos_start, arity['pos_end']),
        [var_name_tok['value'], Elixir.Map.get(arity, 'value')]
    )

def make_pipe_node(file, left_node, right_node):
    (_, {"start": pos_start}, _) = left_node
    (_, {"end": pos_end}, _) = right_node

    (:pipe, gen_meta(file, pos_start, pos_end), [left_node, right_node])

def make_case_node(file, expr, cases, pos_start, pos_end):
    (
        :case,
        gen_meta(file, pos_start, pos_end),
        [expr, cases]
    )

def make_statements_node(file, statements, pos_start, pos_end):
    (
        :statements,
        gen_meta(file, pos_start, pos_end),
        statements
    )

def make_atom_node(file, tok):
    (
        :atom,
        gen_meta(file, tok['pos_start'], tok['pos_end']),
        [tok['value']]
    )

def make_list_node(file, element_nodes, pos_start, pos_end):
    (
        :list,
        gen_meta(file, pos_start, pos_end),
        element_nodes
    )

def make_map_node(file, pairs_list, pos_start, pos_end):
    (
        :map,
        gen_meta(file, pos_start, pos_end),
        pairs_list
    )

def make_tuple_node(file, element_nodes, pos_start, pos_end):
    (
        :tuple,
        gen_meta(file, pos_start, pos_end),
        element_nodes
    )


def make_patternmatch_node(file, left_node, right_node, pos_start, pos_end):
    (
        :pattern,
        gen_meta(file, pos_start, pos_end),
        [left_node, right_node]
    )


def make_raise_node(file, expr, pos_start):
    (_, {"end": pos_end}, _) = expr

    (
        :raise,
        gen_meta(file, pos_start, pos_end),
        [expr]
    )


def make_funcdef_node(file, var_name_tok, arg_nodes, body_node, docstring, pos_start):
    (_, {"end": pos_end}, _) = body_node

    (
        :def,
        Elixir.Map.merge(
            gen_meta(file, pos_start, pos_end),
            {"docstring": docstring}
        ),
        [var_name_tok['value'], arg_nodes, body_node]
    )

def make_lambda_node(file, var_name_tok, arg_nodes, body_node, pos_start):
    (_, {"end": pos_end}, _) = body_node

    (
        :lambda,
        gen_meta(file, pos_start, pos_end),
        [arg_nodes, body_node]
    )



def make_call_node(file, node_to_call, arg_nodes, keywords, pos_end):
    (_, {"start": pos_start}, _) = node_to_call

    (
        :call,
        gen_meta(file, pos_start, pos_end),
        [node_to_call, arg_nodes, keywords, False]
    )

def make_unary_node(file, tok, node):
    operation = case:
        tok['type'] == "KEYWORD" and tok['value'] == "not" -> :not
        tok['type'] == "MINUS" -> :minus
        tok['type'] == "PLUS" -> :plus

    (
        :unary,
        gen_meta(file, tok['pos_start'], tok['pos_end']),
        [operation, node]
    )

def make_bin_op_node(file, left, op_tok, right):
    names = ["PLUS","MINUS","MUL","DIV","GT","GTE","LT","LTE","EE", "NE", "POW", "IN"]

    op = case:
        op_tok['type'] in names -> Elixir.String.downcase(op_tok['type'])
        op_tok['type'] == 'KEYWORD' and op_tok['value'] == 'and' -> 'and'
        op_tok['type'] == 'KEYWORD' and op_tok['value'] == 'or' -> 'or'
        op_tok['type'] == 'KEYWORD' and op_tok['value'] == 'in' -> 'in'

    op = Elixir.String.to_atom(op)

    (_, {"start": pos_start}, _) = left
    (_, {"end": pos_end}, _) = right

    (:binop, gen_meta(file, pos_start, pos_end), [left, op, right])

def make_try_node(file, try_block_node, exceptions, finally_block, pos_start, pos_end):
    (
        :try,
        gen_meta(file, pos_start, pos_end),
        [try_block_node, exceptions, finally_block]
    )


def make_unpack(file, node_to_unpack <- (_, {"end": pos_end}, _), pos_start):
    # unpack operator have different behaviour depending in
    # what side of matching it is
    (
        :unpack,
        gen_meta(file, pos_start, pos_end),
        [node_to_unpack]
    )

def make_spread(file, node_to_spread <- (_, {"end": pos_end}, _), pos_start):
    (
        :spread,
        gen_meta(file, pos_start, pos_end),
        [node_to_spread]
    )

def make_protocol_node(file, var_name_tok, functions, pos_start, pos_end):
    (
        :protocol,
        gen_meta(file, pos_start, pos_end),
        [var_name_tok['value'], functions]
    )

def make_func_protocol_node(file, var_name_tok, arg_nodes, docstring, pos_start, pos_end):
    (
        :protocol_function,
        Elixir.Map.merge(
            gen_meta(file, pos_start, pos_end),
            {"docstring": docstring}
        ),
        [var_name_tok['value'], arg_nodes]
    )

def make_impl_node(file, protocol_name, type, functions, pos_start, pos_end):
    (
        :impl,
        gen_meta(file, pos_start, pos_end),
        [protocol_name, type, functions]
    )
