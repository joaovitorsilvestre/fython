import Utils

import BinOpNode

import UnaryOpNode

def convert(node):
    func = case Map.get(node, "NodeType"):
        "StatementsNode"    -> lambda: convert_statements_node(node)
        "NumberNode"        -> lambda: convert_number_node(node)
        "AtomNode"          -> lambda: convert_atom_node(node)
        "ListNode"          -> lambda: "Not implemented for 'ListNode'"
        "VarAssignNode"     -> lambda: "Not implemented for 'VarAssignNode'"
        "IfNode"            -> lambda: "Not implemented for 'IfNode'"
        "VarAccessNode"     -> lambda: "Not implemented for 'VarAccessNode'"
        "UnaryOpNode"       -> lambda: UnaryOpNode.convert_unaryop_node(&convert/1, node)
        "BinOpNode"         -> lambda: BinOpNode.convert_binop_node(&convert/1, node)
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

def make_line(node):
    number = node |> Map.get("pos_start") |> Map.get("ln")
    Utils.join_str(["[line: ", number, "]"])

def convert_number_node(node):
    node |> Map.get("tok") |> Map.get("value") |> to_string()

def convert_atom_node(node):
    Utils.join_str([":", node |> Map.get("tok") |> Map.get("value")])

def convert_statements_node(node):
    line = make_line(node)

    content = node
        |> Map.get("statement_nodes")
        |> Enum.map(lambda i: convert(i))

    case Enum.count(content):
        1 -> content
        _ -> Utils.join_str([
            "{:__block__, ", line, ", [", Enum.join(content, ", "), "]}"
        ])
