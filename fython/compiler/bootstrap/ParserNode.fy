def convert(node):
    func = case Map.get(node, "NodeType"):
        "StatementsNode"    -> lambda: convert_statements_node(node)
        "NumberNode"        -> lambda: convert_number_node(node)
        "AtomNode"          -> lambda: "Not implemented for 'AtomNode'"
        "StatementsNode"    -> lambda: "Not implemented for 'StatementsNode'"
        "ListNode"          -> lambda: "Not implemented for 'ListNode'"
        "VarAssignNode"     -> lambda: "Not implemented for 'VarAssignNode'"
        "IfNode"            -> lambda: "Not implemented for 'IfNode'"
        "VarAccessNode"     -> lambda: "Not implemented for 'VarAccessNode'"
        "UnaryOpNode"       -> lambda: "Not implemented for 'UnaryOpNode'"
        "BinOpNode"         -> lambda: "Not implemented for 'BinOpNode'"
        "FuncDefNode"       -> lambda: "Not implemented for 'FuncDefNode'"
        "LambdaNode"        -> lambda: "Not implemented for 'LambdaNode'"
        "CallNode"          -> lambda: "Not implemented for 'CallNode'"
        "StringNode"        -> lambda: "Not implemented for 'StringNode'"
        "PipeNode"          -> lambda: "Not implemented for 'PipeNode'"
        "e_pipe"            -> lambda: "Not implemented for 'e_pipe'"
        "MapNode"           -> lambda: "Not implemented for 'MapNode'"
        "ImportNode"        -> lambda: "Not implemented for 'ImportNode'"
        "CaseNode"          -> lambda: "Not implemented for 'CaseNode'"

    func()

def make_line(number):
    1

def convert_number_node(node):
    1


def convert_statements_node(node):
    "not implemented"