def make_number_node(tok):
    {"tok": tok, "NodeType": "NumberNode"}

def make_unary_node(tok, node):
    {"tok": tok, "node": node, "NodeType": "UnaryOpNode"}

def make_bin_op_node(left, op_tok, right):
    {"left": left, "op_tok": op_tok, "right": right, "NodeType": "BinOpNode"}
