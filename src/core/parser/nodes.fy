def node_types_accept_pattern():
    ['ListNode', 'MapNode', 'TupleNode', 'VarAccessNode']

def node_types_accept_pattern_in_function_argument():
    Elixir.List.flatten(
        node_types_accept_pattern(),
        ['NumberNode', 'StringNode', 'AtomNode']
    )

def gen_meta(pos_start, pos_end):
    convert_pos = lambda {"idx": idx, "ln": ln, "col": col}:
        (idx, ln, col)

    {"file": "unkown", "start": convert_pos(pos_start), "end": convert_pos(pos_end)}

def make_number_node(tok):
    {
        "NodeType": "NumberNode",
        "tok": tok,
        "pos_start": Elixir.Map.get(tok, "pos_start"),
        "pos_end": Elixir.Map.get(tok, "pos_end"),
        "_new": (
            :number,
            gen_meta(tok['pos_start'], tok['pos_end']),
            [tok['value']]
        )
    }

def make_string_node(tok):
    {
        "NodeType": "StringNode",
        "tok": tok,
        "pos_start": Elixir.Map.get(tok, "pos_start"),
        "pos_end": Elixir.Map.get(tok, "pos_end"),
        "_new": (
            :string,
            gen_meta(tok['pos_start'], tok['pos_end']),
            [tok['value']]
        )
    }

def make_varaccess_node(var_name_tok, pinned):
    {
        "NodeType": "VarAccessNode",
        "var_name_tok": var_name_tok,
        "pinned": pinned,
        "pos_start": Elixir.Map.get(var_name_tok, "pos_start"),
        "pos_end": Elixir.Map.get(var_name_tok, "pos_end"),
        "_new": (
            :var,
            gen_meta(var_name_tok['pos_start'], var_name_tok['pos_end']),
            [pinned, var_name_tok['value']]
        )
    }

def make_staticaccess_node(node_left, node_value, pos_end):
    {
        "NodeType": "StaticAccessNode",
        "node": node_left,
        "node_value": node_value,
        "pos_start": Elixir.Map.get(node_left, "pos_start"),
        "pos_end": pos_end
    }

def make_if_node(comp_expr, true_expr, false_expr):
    {
        "NodeType": "IfNode",
        "comp_expr": comp_expr,
        "true_case": true_expr,
        "false_case": false_expr,
        "pos_start": Elixir.Map.get(comp_expr, "pos_start"),
        "pos_end": Elixir.Map.get(false_expr, "pos_end")
    }

def make_funcasvariable_node(var_name_tok, arity, pos_start):
    {
        "NodeType": "FuncAsVariableNode",
        "var_name_tok": var_name_tok,
        "arity": Elixir.String.to_integer(Elixir.Map.get(arity, 'value')),
        "pos_start": pos_start,
        "pos_end": Elixir.Map.get(arity, "pos_end")
    }

def make_pipe_node(left_node, right_node):
    {
        "NodeType": "PipeNode",
        "left_node": left_node,
        "right_node": right_node,
        "pos_start": Elixir.Map.get(left_node, "pos_start"),
        "pos_end": Elixir.Map.get(right_node, "pos_end")
    }

def make_case_node(expr, cases, pos_start, pos_end):
    {
        "NodeType": "CaseNode",
        "expr": expr,
        "cases": cases,
        "pos_start": pos_start,
        "pos_end": pos_end
    }

def make_statements_node(statements, pos_start, pos_end):
    {
        "NodeType": "StatementsNode",
        "statement_nodes": statements,
        "pos_start": pos_start,
        "pos_end": pos_end
    }

def make_atom_node(tok):
    {
        "NodeType": "AtomNode",
        "tok": tok,
        "pos_start": Elixir.Map.get(tok, "pos_start"),
        "pos_end": Elixir.Map.get(tok, "pos_end"),
        "_new": (
            :atom,
            gen_meta(tok['pos_start'], tok['pos_end']),
            [tok['value']]
        )
    }

def make_list_node(element_nodes, pos_start, pos_end):
    {
        "NodeType": "ListNode",
        "element_nodes": element_nodes,
        "pos_start": pos_start,
        "pos_end": pos_end,
        "_new": (
            :list,
            gen_meta(pos_start, pos_end),
            element_nodes
        )
    }

def make_map_node(pairs_list, pos_start, pos_end):
    {
        "NodeType": "MapNode",
        "pairs_list": pairs_list,
        "pos_start": pos_start,
        "pos_end": pos_end
    }

def make_tuple_node(element_nodes, pos_start, pos_end):
    {
        "NodeType": "TupleNode",
        "element_nodes": element_nodes,
        "pos_start": pos_start,
        "pos_end": pos_end,
        "_new": (
            :tuple,
            gen_meta(pos_start, pos_end),
            element_nodes
        )
    }


def make_patternmatch_node(left_node, right_node, pos_start, pos_end):
    {
        "NodeType": "PatternMatchNode",
        "left_node": left_node,
        "right_node": right_node,
        "pos_start": pos_start,
        "pos_end": pos_end,
        "_new": (
            :pattern,
            gen_meta(pos_start, pos_end),
            [left_node, right_node]
        )
    }


def make_raise_node(expr, pos_start):
    {
        "NodeType": "RaiseNode",
        "expr": expr,
        "pos_start": pos_start,
        "pos_end": Elixir.Map.get(expr, 'pos_end')
    }


def make_funcdef_node(var_name_tok, arg_nodes, body_node, docstring, pos_start):
    {
        "NodeType": "FuncDefNode",
        "var_name_tok": var_name_tok,
        "arg_nodes": arg_nodes,
        "arity": Elixir.Enum.count(arg_nodes),
        "body_node": body_node,
        "docstring": docstring,
        "pos_start": pos_start,
        "pos_end": Elixir.Map.get(body_node, 'pos_end')
    }

def make_lambda_node(var_name_tok, arg_nodes, body_node, pos_start):
    Elixir.Map.merge(
        make_funcdef_node(var_name_tok, arg_nodes, body_node, None, pos_start),
        {"NodeType": "LambdaNode"}
    )


def make_call_node(node_to_call, arg_nodes, keywords, pos_end):
    {
        "NodeType": "CallNode",
        "node_to_call": node_to_call,
        "arg_nodes": arg_nodes,
        "keywords": keywords,
        "arity": Elixir.Enum.count(arg_nodes),
        "pos_start": Elixir.Map.get(node_to_call, 'pos_start'),
        "pos_end": pos_end,
        "local_call": False
    }

def make_unary_node(tok, node):
    operation = case:
        tok['type'] == "KEYWORD" and tok['value'] == "not" -> :not
        tok['type'] == "MINUS" -> :minus
        tok['type'] == "PLUS" -> :plus

    case Core.Parser.Utils.valid_node?(node):
        [False, reason] -> raise reason
        [True, _] -> {
            "NodeType": "UnaryOpNode",
            "op_tok": tok,
            "node": node,
            "pos_start": Elixir.Map.get(tok, "pos_start"),
            "pos_end": Elixir.Map.get(tok, "pos_end"),
            "_new": (
                :unary,
                gen_meta(tok['pos_start'], tok['pos_end']),
                [operation, node]
            )
        }

def make_bin_op_node(left, op_tok, right):
    case Core.Parser.Utils.valid_node?(left):
        [False, reason] -> raise reason
        [True, _] ->
            names = ["PLUS","MINUS","MUL","DIV","GT","GTE","LT","LTE","EE", "NE", "POW", "IN"]

            op = case:
                op_tok['type'] in names -> Elixir.String.downcase(op_tok['type'])
                op_tok['type'] == 'KEYWORD' and op_tok['value'] == 'and' -> 'and'
                op_tok['type'] == 'KEYWORD' and op_tok['value'] == 'or' -> 'or'
                op_tok['type'] == 'KEYWORD' and op_tok['value'] == 'in' -> 'in'

            op = Elixir.String.to_atom(op)

            case Core.Parser.Utils.valid_node?(right):
                [False, reason] -> raise reason
                [True, _] -> {
                    "NodeType": "BinOpNode",
                    "left_node": left,
                    "op_tok": op_tok,
                    "right_node": right,
                    "pos_start": Elixir.Map.get(left, "pos_start"),
                    "pos_end": Elixir.Map.get(right, "pos_end"),
                    "_new": (
                        :binop,
                        gen_meta(left['pos_start'], right['pos_end']),
                        [left, op, right]
                    )
                }


def make_try_node(try_block_node, exceptions, finally_block, pos_start, pos_end):
    {
        "NodeType": "TryNode",
        "try_block_node": try_block_node,
        "exceptions": exceptions,
        "finally_block": finally_block,
        "pos_start": pos_start,
        "pos_end": pos_end
    }

