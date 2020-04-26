def make_number_node(tok):
    {
        "tok": tok,
        "NodeType": "NumberNode"
    }

def make_unary_node(tok, node):
    case Core.Parser.Utils.valid_node?(node):
        [False, reason] -> raise reason
        [True, _] -> {
            "tok": tok,
            "node": node,
            "NodeType": "UnaryOpNode"
        }

def make_bin_op_node(left, op_tok, right):
    case Core.Parser.Utils.valid_node?(left):
        [False, reason] -> raise reason
        [True, _] ->

            case Core.Parser.Utils.valid_node?(right):
                [False, reason] -> raise reason
                [True, _] -> {
                    "left": left,
                    "op_tok": op_tok,
                    "right": right,
                    "NodeType": "BinOpNode"
                }
