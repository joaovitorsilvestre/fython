def node_types_accept_pattern():
    [:list, :map, :tuple, :var]

def node_types_accept_pattern_in_function_argument():
    Elixir.List.flatten(
        node_types_accept_pattern(),
        [:number, :string, :atom]
    )

def gen_meta(pos_start, pos_end):
    convert_pos = lambda pos:
        # TODO Temp fix while pos of lexer doesnt follow new ast
        case Elixir.Kernel.is_map(pos):
            True ->
                {"idx": idx, "ln": ln, "col": col} = pos
                (idx, ln, col)
            False -> pos

    {"file": "unkown", "start": convert_pos(pos_start), "end": convert_pos(pos_end)}

def make_number_node(tok):
    (
        :number,
        gen_meta(tok['pos_start'], tok['pos_end']),
        [tok['value']]
    )

def make_string_node(tok):
    (
        :string,
        gen_meta(tok['pos_start'], tok['pos_end']),
        [tok['value']]
    )

def make_varaccess_node(var_name_tok, pinned):
    (
        :var,
        gen_meta(var_name_tok['pos_start'], var_name_tok['pos_end']),
        [pinned, var_name_tok['value']]
    )

def make_staticaccess_node(node_left, node_value, pos_end):
    (_, {"start": pos_start}, _) = node_left

    (
        :static_access,
        gen_meta(pos_start, pos_end),
        [node_left, node_value]
    )

def make_if_node(comp_expr, true_expr, false_expr):
    (_, {"start": pos_start}, _) = comp_expr
    (_, {"end": pos_end}, _) = false_expr

    (
        :if,
        gen_meta(pos_start, pos_end),
        [comp_expr, true_expr, false_expr]
    )

def make_funcasvariable_node(var_name_tok, arity, pos_start):
    (
        :func,
        gen_meta(pos_start, arity['pos_end']),
        [var_name_tok['value'], Elixir.Map.get(arity, 'value')]
    )

def make_pipe_node(left_node, right_node):
    (_, {"start": pos_start}, _) = left_node
    (_, {"end": pos_end}, _) = right_node

    (:pipe, gen_meta(pos_start, pos_end), [left_node, right_node])

def make_case_node(expr, cases, pos_start, pos_end):
    (
        :case,
        gen_meta(pos_start, pos_end),
        [expr, cases]
    )

def make_statements_node(statements, pos_start, pos_end):
    (
        :statements,
        gen_meta(pos_start, pos_end),
        statements
    )

def make_atom_node(tok):
    (
        :atom,
        gen_meta(tok['pos_start'], tok['pos_end']),
        [tok['value']]
    )

def make_list_node(element_nodes, pos_start, pos_end):
    (
        :list,
        gen_meta(pos_start, pos_end),
        element_nodes
    )

def make_map_node(pairs_list, pos_start, pos_end):
    (
        :map,
        gen_meta(pos_start, pos_end),
        pairs_list
    )

def make_tuple_node(element_nodes, pos_start, pos_end):
    (
        :tuple,
        gen_meta(pos_start, pos_end),
        element_nodes
    )


def make_patternmatch_node(left_node, right_node, pos_start, pos_end):
    (
        :pattern,
        gen_meta(pos_start, pos_end),
        [left_node, right_node]
    )


def make_raise_node(expr, pos_start):
    (_, {"end": pos_end}, _) = expr

    (
        :raise,
        gen_meta(pos_start, pos_end),
        [expr]
    )


def make_funcdef_node(var_name_tok, arg_nodes, body_node, docstring, pos_start):
    (_, {"end": pos_end}, _) = body_node

    (
        :def,
        Elixir.Map.merge(
            gen_meta(pos_start, pos_end),
            {"docstring": docstring}
        ),
        [var_name_tok['value'], arg_nodes, body_node]
    )

def make_lambda_node(var_name_tok, arg_nodes, body_node, pos_start):
    (_, {"end": pos_end}, _) = body_node

    (
        :lambda,
        gen_meta(pos_start, pos_end),
        [arg_nodes, body_node]
    )



def make_call_node(node_to_call, arg_nodes, keywords, pos_end):
    (_, {"start": pos_start}, _) = node_to_call

    (
        :call,
        gen_meta(pos_start, pos_end),
        [node_to_call, arg_nodes, keywords, False]
    )

def make_unary_node(tok, node):
    operation = case:
        tok['type'] == "KEYWORD" and tok['value'] == "not" -> :not
        tok['type'] == "MINUS" -> :minus
        tok['type'] == "PLUS" -> :plus

    (
        :unary,
        gen_meta(tok['pos_start'], tok['pos_end']),
        [operation, node]
    )

def make_bin_op_node(left, op_tok, right):
    names = ["PLUS","MINUS","MUL","DIV","GT","GTE","LT","LTE","EE", "NE", "POW", "IN"]

    op = case:
        op_tok['type'] in names -> Elixir.String.downcase(op_tok['type'])
        op_tok['type'] == 'KEYWORD' and op_tok['value'] == 'and' -> 'and'
        op_tok['type'] == 'KEYWORD' and op_tok['value'] == 'or' -> 'or'
        op_tok['type'] == 'KEYWORD' and op_tok['value'] == 'in' -> 'in'

    op = Elixir.String.to_atom(op)

    (_, {"start": pos_start}, _) = left
    (_, {"end": pos_end}, _) = right

    (:binop, gen_meta(pos_start, pos_end), [left, op, right])

def make_try_node(try_block_node, exceptions, finally_block, pos_start, pos_end):
    (
        :try,
        gen_meta(pos_start, pos_end),
        [try_block_node, exceptions, finally_block]
    )


def make_unpack(node_to_unpack <- (_, {"end": pos_end}, _), pos_start):
    # unpack operator have different behaviour depending in
    # what side of matching it is
    (
        :unpack,
        gen_meta(pos_start, pos_end),
        [node_to_unpack]
    )

def make_spread(node_to_spread <- (_, {"end": pos_end}, _), pos_start):
    (
        :spread,
        gen_meta(pos_start, pos_end),
        [node_to_spread]
    )
