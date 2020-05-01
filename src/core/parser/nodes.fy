def make_number_node(tok):
    {
        "NodeType": "NumberNode",
        "tok": tok,
        "pos_start": Map.get(tok, "pos_start"),
        "pos_end": Map.get(tok, "pos_end")
    }

def make_string_node(tok):
    {
        "NodeType": "StringNode",
        "tok": tok,
        "pos_start": Map.get(tok, "pos_start"),
        "pos_end": Map.get(tok, "pos_end")
    }

def make_varaccess_node(var_name_tok):
    {
        "NodeType": "VarAccessNode",
        "var_name_tok": var_name_tok,
        "pos_start": Map.get(var_name_tok, "pos_start"),
        "pos_end": Map.get(var_name_tok, "pos_end")
    }

def make_varassign_node(var_name_tok, value_node):
    {
        "NodeType": "VarAssignNode",
        "var_name_tok": var_name_tok,
        "value_node": value_node,
        "pos_start": Map.get(var_name_tok, "pos_start"),
        "pos_end": Map.get(value_node, "pos_end")
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
        "NodeType": "VarAccessNode",
        "tok": tok,
        "pos_start": Map.get(tok, "pos_start"),
        "pos_end": Map.get(tok, "pos_end")
    }

def make_list_node(element_nodes, pos_start, pos_end):
    {
        "NodeType": "ListNode",
        "element_nodes": element_nodes,
        "pos_start": pos_start,
        "pos_end": pos_end
    }

def make_map_node(pairs_list, pos_start, pos_end):
    {
        "NodeType": "MapNode",
        "pairs_list": pairs_list,
        "pos_start": pos_start,
        "pos_end": pos_end
    }

def make_unary_node(tok, node):
    case Core.Parser.Utils.valid_node?(node):
        [False, reason] -> raise reason
        [True, _] -> {
            "NodeType": "UnaryOpNode",
            "tok": tok,
            "node": node,
            "pos_start": Map.get(tok, "pos_start"),
            "pos_end": Map.get(tok, "pos_end")
        }

def make_bin_op_node(left, op_tok, right):
    case Core.Parser.Utils.valid_node?(left):
        [False, reason] -> raise reason
        [True, _] ->

            case Core.Parser.Utils.valid_node?(right):
                [False, reason] -> raise reason
                [True, _] -> {
                    "NodeType": "BinOpNode",
                    "left": left,
                    "op_tok": op_tok,
                    "right": right,
                    "pos_start": Map.get(left, "pos_start"),
                    "pos_end": Map.get(right, "pos_end")
                }
