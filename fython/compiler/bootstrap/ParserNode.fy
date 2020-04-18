import Utils

import BinOpNode

import UnaryOpNode

def convert(node):
    func = case Map.get(node, "NodeType"):
        "StatementsNode"    -> lambda: convert_statements_node(node)
        "NumberNode"        -> lambda: convert_number_node(node)
        "AtomNode"          -> lambda: convert_atom_node(node)
        "ListNode"          -> lambda: convert_list_node(node)
        "VarAssignNode"     -> lambda: convert_varassign_node(node)
        "IfNode"            -> lambda: convert_if_node(node)
        "VarAccessNode"     -> lambda: convert_varaccess_node(node)
        "UnaryOpNode"       -> lambda: UnaryOpNode.convert_unaryop_node(&convert/1, node)
        "BinOpNode"         -> lambda: BinOpNode.convert_binop_node(&convert/1, node)
        "FuncDefNode"       -> lambda: "Not implemented for 'FuncDefNode'"
        "LambdaNode"        -> lambda: "Not implemented for 'LambdaNode'"
        "CallNode"          -> lambda: "Not implemented for 'CallNode'"
        "StringNode"        -> lambda: convert_string_node(node)
        "PipeNode"          -> lambda: "Not implemented for 'PipeNode'"
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

def convert_string_node(node):
    Utils.join_str(['"', node |> Map.get("tok") |> Map.get("value"), '"'])

def convert_varaccess_node(node):
    tok_value = node |> Map.get("var_name_tok") |> Map.get("value")

    case tok_value:
        "True" -> "true"
        "False" -> "false"
        _ -> Utils.join_str(["{:", tok_value, ", [], Elixir}"])

def convert_varassign_node(node):
    Utils.join_str([
        "{:=, [], [{:",
        node |> Map.get("var_name_tok") |> Map.get("value"),
        ", [], Elixir}, ",
        convert(node |> Map.get("value_node")),
        "]}"
    ])

def convert_if_node(node):
    comp_expr = convert(node |> Map.get("comp_expr"))
    true_case = convert(node |> Map.get("true_case"))
    false_case = convert(node |> Map.get("false_case"))

    Utils.join_str([
        "{:if, [context: Elixir, import: Kernel], [",
        comp_expr,
        ", [do: ",
        true_case,
        ", else: ",
        false_case,
        "]]}"
    ])

def convert_list_node(node):
    Utils.join_str([
        "[",
        Enum.join(Enum.map(node |> Map.get("element_nodes"), &convert/1), ", "),
        "]"
    ])

def convert_statements_node(node):
    line = make_line(node)

    content = node
        |> Map.get("statement_nodes")
        |> Enum.map(lambda i: convert(i))

    case Enum.count(content):
        1 -> content
        _ -> Utils.join_str([
            '{:__block__, ', line, ', [', Enum.join(content, ', '), ']}'
        ])
