import Utils

import BinOpNode

import UnaryOpNode

import ImportNode

import CallNode

import PipeNode

def convert(node):
    func = case Map.get(node, "NodeType"):
        "StatementsNode"    -> convert_statements_node(node)
        "NumberNode"        -> convert_number_node(node)
        "AtomNode"          -> convert_atom_node(node)
        "ListNode"          -> convert_list_node(node)
        "VarAssignNode"     -> convert_varassign_node(node)
        "IfNode"            -> convert_if_node(node)
        "VarAccessNode"     -> convert_varaccess_node(node)
        "UnaryOpNode"       -> UnaryOpNode.convert_unaryop_node(&convert/1, node)
        "BinOpNode"         -> BinOpNode.convert_binop_node(&convert/1, node)
        "FuncDefNode"       -> convert_deffunc_node(node)
        "LambdaNode"        -> convert_lambda_node(node)
        "CallNode"          -> CallNode.convert_call_node(&convert/1, node)
        "StringNode"        -> convert_string_node(node)
        "PipeNode"          -> PipeNode.convert_pipe_node(node)
        "MapNode"           -> convert_map_node(node)
        "ImportNode"        -> ImportNode.convert_import_node(node)
        "CaseNode"          -> convert_case_node(node)
        "InNode"            -> convert_in_node(node)

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
        "None" -> "nil"
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

def convert_lambda_node(node):
    params = node
        |> Map.get("arg_name_toks")
        |> Enum.map(lambda param:
            Utils.join_str([
                "{:",
                param |> Map.get('value'),
                ", [context: Elixir, import: IEx.Helpers], Elixir}"
            ])
        )
        |> Enum.join(", ")

    params = ['[', params, ']'] |> Enum.join('')

    Utils.join_str([
        "{:fn, [], [{:->, [], [",
        params,
        ", ",
        convert(node |> Map.get('body_node')),
        "]}]}"
    ])

def convert_list_node(node):
    Utils.join_str([
        "[",
        Enum.join(Enum.map(node |> Map.get("element_nodes"), &convert/1), ", "),
        "]"
    ])

def convert_map_node(node):
    pairs = node
        |> Map.get("pairs_list")
        |> Enum.map(lambda pair:
            key = pair |> Enum.at(0)
            value = pair |> Enum.at(1)
            Utils.join_str(["{", convert(key), ", ", convert(value), "}"])
        )
        |> Enum.join(', ')

    Utils.join_str(["{:%{}, [], [", pairs, "]}"])

def convert_statements_node(node):
    content = node
        |> Map.get("statement_nodes")
        |> Enum.map(lambda i: convert(i))

    case Enum.count(content):
        1 -> Enum.at(content, 0)
        _ -> Utils.join_str([
            '{:__block__, [line: 0], [', Enum.join(content, ', '), ']}'
        ])

def convert_deffunc_node(node):
    name = node |> Map.get("var_name_tok") |> Map.get("value")
    statements_node = node |> Map.get("body_node")

    arguments = node
        |> Map.get("arg_name_toks")
        |> Enum.map(lambda argument:
            Utils.join_str(["{:", Map.get(argument, "value"), ", [], Elixir}"])
        )
        |> Enum.join(', ')

    Utils.join_str([
        "{:def, [line: 0], [{:", name, ", [line: 0], [",
        arguments, "]}, [do: ", convert(statements_node), "]]}"
    ])

def convert_case_node(node):
    expr = convert(node |> Map.get("expr"))

    arguments = node
        |> Map.get("cases")
        |> Enum.map(lambda left_right:
            left = Enum.at(left_right, 0)
            right = Enum.at(left_right, 1)

            Enum.join([
                "{:->, [], [[", convert(left), "], ", convert(right), "]}"
            ], '')
        )
        |> Enum.join(', ')

    Enum.join([
        "{:case, [], [", expr, ", [do: [", arguments, "]]]}"
    ])

def convert_in_node(node):
    left = Map.get(node, "left_expr") |> convert()
    right = Map.get(node, "right_expr") |> convert()

    Enum.join([
        "{: in, [context: Elixir, import: Kernel], [", left, ", ", right, "]}"
    ])

def convert_module_to_ast(module_name, compiled_body):
    module_name = case String.contains?(module_name, "."):
        False -> Enum.join([":", module_name])
        True ->
            module_name = module_name
                |> String.split('.')
                |> Enum.map(lambda i: Enum.join([":", i]))
                |> Enum.join(", ")

            Enum.join([
                "{:__aliases__, [alias: false], [",
                module_name,
                "]}"
            ])

    Utils.join_str([
        "{:defmodule, [line: 1], ",
        "[{:__aliases__, [line: 1], [", module_name, "]}, ",
        "[do: ", compiled_body, "]]}"
    ])
