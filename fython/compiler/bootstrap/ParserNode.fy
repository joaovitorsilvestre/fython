def convert(node):
    IO.inspect(node)

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

def join_str(list):
    list |> Enum.map(lambda i: i |> to_string()) |> Enum.join('')

def make_line(node):
    number = node |> Map.get("pos_start") |> Map.get("ln")
    join_str(["[line: ", number, "]"])

def convert_number_node(node):
    node |> Map.get("tok") |> Map.get("value") |> to_string()

def convert_statements_node(node):
    line = make_line(node)

    content = node
        |> Map.get("statement_nodes")
        |> Enum.map(lambda i: convert(i))

    case Enum.count(content):
        1 -> content
        _ -> join_str([
            "{:__block__, ", line, ", [", Enum.join(content, ", "), "]}"
        ])
