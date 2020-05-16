def convert(node):
    func = case Map.get(node, "NodeType"):
        "StatementsNode"    -> convert_statements_node(node)
        "NumberNode"        -> convert_number_node(node)
        "AtomNode"          -> convert_atom_node(node)
        "ListNode"          -> convert_list_node(node)
        "PatternMatchNode"  -> convert_patternmatch_node(node)
        "IfNode"            -> convert_if_node(node)
        "VarAccessNode"     -> convert_varaccess_node(node)
        "UnaryOpNode"       -> convert_unaryop_node(node)
        "BinOpNode"         -> convert_binop_node(node)
        "FuncDefNode"       -> convert_deffunc_node(node)
        "LambdaNode"        -> convert_lambda_node(node)
        "CallNode"          -> convert_call_node(node)
        "StringNode"        -> convert_string_node(node)
        "PipeNode"          -> convert_pipe_node(node)
        "MapNode"           -> convert_map_node(node)
        "ImportNode"        -> convert_import_node(node)
        "CaseNode"          -> convert_case_node(node)
        "InNode"            -> convert_in_node(node)
        "TupleNode"         -> convert_tuple_node(node)
        "RaiseNode"         -> convert_raise_node(node)
        "FuncAsVariableNode" -> convert_funcasvariable_node(node)

def convert_number_node(node):
    node |> Map.get("tok") |> Map.get("value") |> to_string()

def convert_atom_node(node):
    Enum.join([":", node |> Map.get("tok") |> Map.get("value")])

def convert_string_node(node):
    value = node
        |> Map.get("tok")
        |> Map.get("value")

    # We need to remove this dependency, eventually
    # Convert to json is te easiest way that we found for scape
    # `"` and `/` (and probably another chars too)
    Enum.join(['"', value ,'"'])

def convert_varaccess_node(node):
    tok_value = node |> Map.get("var_name_tok") |> Map.get("value")

    case tok_value:
        "True" -> "true"
        "False" -> "false"
        "None" -> "nil"
        _ -> Enum.join(["{:", tok_value, ", [], Elixir}"])

def convert_patternmatch_node(node):
    left = Map.get(node, 'left_node') |> convert()
    right = Map.get(node, 'right_node') |> convert()

    Enum.join([
        "{:=, ",
        "[], ",
        "[", left , ", ", right , "]",
        "}"
    ])

def convert_if_node(node):
    comp_expr = convert(node |> Map.get("comp_expr"))
    true_case = convert(node |> Map.get("true_case"))
    false_case = convert(node |> Map.get("false_case"))

    Enum.join([
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
            Enum.join([
                "{:",
                param |> Map.get('value'),
                ", [context: Elixir, import: IEx.Helpers], Elixir}"
            ])
        )
        |> Enum.join(", ")

    params = ['[', params, ']'] |> Enum.join('')

    Enum.join([
        "{:fn, [], [{:->, [], [",
        params,
        ", ",
        convert(node |> Map.get('body_node')),
        "]}]}"
    ])

def convert_list_node(node):
    Enum.join([
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
            Enum.join(["{", convert(key), ", ", convert(value), "}"])
        )
        |> Enum.join(', ')

    r = Enum.join(["{:%{}, [], [", pairs, "]}"])

def convert_statements_node(node):
    content = node
        |> Map.get("statement_nodes")
        |> Enum.map(lambda i: convert(i))

    case Enum.count(content):
        1 -> Enum.at(content, 0)
        _ -> Enum.join([
            '{:__block__, [line: 0], [', Enum.join(content, ', '), ']}'
        ])

def convert_deffunc_node(node):
    name = node |> Map.get("var_name_tok") |> Map.get("value")
    statements_node = node |> Map.get("body_node")

    arguments = node
        |> Map.get("arg_name_toks")
        |> Enum.map(lambda argument:
            Enum.join(["{:", Map.get(argument, "value"), ", [], Elixir}"])
        )
        |> Enum.join(', ')

    Enum.join([
        "{:def, [line: 0], [{:", name, ", [line: 0], [",
        arguments, "]}, [do: ", convert(statements_node), "]]}"
    ])

def convert_case_node(node):
    expr = convert(node |> Map.get("expr")) if node |> Map.get("expr") else None

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

    case expr:
        None -> Enum.join([
                "{:cond, [], [[do: [", arguments, "]]]}"
            ])
        _ -> Enum.join([
                "{:case, [], [", expr, ", [do: [", arguments, "]]]}"
            ])

def convert_in_node(node):
    left = Map.get(node, "left_expr") |> convert()
    right = Map.get(node, "right_expr") |> convert()

    Enum.join([
        "{:in, [context: Elixir, import: Kernel], [", left, ", ", right, "]}"
    ])

def convert_raise_node(node):
    expr = Map.get(node, "expr") |> convert()

    Enum.join(["{:raise, [context: Elixir, import: Kernel], [", expr, "]}"])

def convert_funcasvariable_node(node):
    name = node |> Map.get("var_name_tok") |> Map.get("value")
    arity = node |> Map.get("arity")
    Enum.join([
        "{:&, [], [{:/, [context: Elixir, import: Kernel], [{:",
        name, ", [], Elixir}, ", arity, "]}]}"
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

    Enum.join([
        "{:defmodule, [line: 1], ",
        "[{:__aliases__, [line: 1], [", module_name, "]}, ",
        "[do: ", compiled_body, "]]}"
    ])

def convert_binop_node(node):
    a = convert(Map.get(node, "left_node"))
    b = convert(Map.get(node, "right_node"))

    simple_ops = {
        "PLUS": '+', "MINUS": '-', "MUL": '*', "DIV": '/',
        "GT": '>', "GTE": '>=', "LT": '<', "LTE": '<=',
        "EE": '==', 'NE': '!='
    }

    tok_type = node |> Map.get("op_tok") |> Map.get("type")
    tok_value = node |> Map.get("op_tok") |> Map.get("value")

    cases = [
        Map.has_key?(simple_ops, tok_type),
        tok_type == "POW",
        tok_type == "KEYWORD" and tok_value == "or",
        tok_type == "KEYWORD" and tok_value == "and"
    ]

    simple_op_node = lambda simple_ops, node, a, b:
        op = simple_ops |> Map.get(node |> Map.get("op_tok") |> Map.get("type"))
        Enum.join([
            "{:", op, ", [context: Elixir, import: Kernel], [", a, ", ", b, "]}"
        ])

    power_op = lambda a, b:
        Enum.join([
            "{{:., [], [:math, :pow]}, [], [", a, ", ", b, "]}"
        ])

    or_op = lambda a, b:
        Enum.join([
            "{:or, [context: Elixir, import: Kernel], [", a, ", ", b, "]}"
        ])

    and_op = lambda a, b:
        Enum.join([
            "{:and, [context: Elixir, import: Kernel], [", a, ", ", b, "]}"
        ])

    case cases:
        [True, _, _, _] -> simple_op_node(simple_ops, node, a, b)
        [_, True, _, _] -> power_op(a, b)
        [_, _,True, _]  -> or_op(a, b)
        [_, _, _,True]  -> and_op(a, b)


def convert_call_node(node):
    args = node
        |> Map.get("arg_nodes")
        |> Enum.map(&convert/1)

    keywords = node
        |> Map.get("keywords")
        |> Map.to_list()
        |> Enum.map(lambda k_v:
            k = elem(k_v, 0)
            v = elem(k_v, 1)
            Enum.join(["[", k, ": ", convert(v), "]"])
        )

    arguments = Enum.join([
        "[",
        [args, keywords] |> List.flatten() |> Enum.join(", "),
        "]"
    ], "")

    func_name = node
        |> Map.get("node_to_call")
        |> Map.get("var_name_tok")
        |> Map.get("value")

    cases = [
        func_name |> String.contains?("."),
        Map.get(node, "local_call")
    ]

    local_call_case = lambda func_name, arguments:
        Enum.join([
            "{{:., [], [{:", func_name, ", [], Elixir}]}, [], ", arguments, "}"
        ])

    module_function_call_case = lambda name,  arguments:
        modules = name |> String.split(".") |> List.pop_at(-1) |> elem(1)
        function = name |> String.split(".") |> Enum.at(-1)

        modules = modules
            |> Enum.map(lambda i: Enum.join([':', i], ''))
            |> Enum.join(', ')

        r = Enum.join([
            '{{:., [], [{:__aliases__, [alias: false], [',
            modules,
            ']}, :', function,']}, [], ', arguments, '}'
        ])

    case cases:
        [True, _] -> module_function_call_case(func_name, arguments)
        [_, True] -> local_call_case(func_name, arguments)
        _         -> Enum.join(["{:", func_name, ", [], ", arguments, "}"])

def convert_import_node(node):
    case Map.get(node, "modules_import"):
        None -> "not implemened from"
        _    ->
            import_commands = node
                |> Map.get("modules_import")
                |> Enum.map(lambda imp:
                    name = Map.get(imp, "name")
                    alias = Map.get(imp, "alias")

                    case String.contains?(name, "."):
                        True ->
                            name = name
                                |> String.split(".")
                                |> Enum.map(lambda i: Enum.join([':', i]))
                                |> Enum.join(', ')
                        False -> Enum.join([':', name])

                    import_command = Enum.join([
                        "{:import, [context: Elixir], ",
                        "[{:__aliases__, [alias: false], ",
                        "[", name, "]}]}"
                    ])

                    result = case Map.get(imp, "alias"):
                        None -> import_command
                        _ -> Enum.join([
                            "{:__block__, [], [",
                                import_command,
                                ", {:alias, [context: Elixir], [",
                                "{:__aliases__, [alias: false], [", name, "]},",
                                "[as: {:__aliases__, [alias: ", name, "], [:", alias,"]}]",
                                "]}",
                            "]}"
                        ])
                    result
                )
                |> Enum.join(', ')

            Enum.join(["{:__block__, [], [", import_commands, "]}"])

def build_single_pipe(node):
    left = node |> Map.get("left_node") |> convert()
    right = node |> Map.get("right_node") |> convert()
    build_single_pipe(left, right)

def build_single_pipe(left, right):
    left = case is_map(left):
        True -> left |> convert()
        False -> left

    right = case is_map(right):
        True -> right |> convert()
        False -> right

    Enum.join([
        "{:|>, [context: Elixir, import: Kernel], [",
        left, ",", right, "]}", ''
    ], "")

def is_pipenode(node):
    (node |> Map.get("NodeType")) == "PipeNode"

def get_childs(right_or_left_node):
    case is_pipenode(right_or_left_node):
        True -> [
            get_childs(right_or_left_node |> Map.get("left_node")),
            get_childs(right_or_left_node |> Map.get("right_node"))
        ]
        False -> [right_or_left_node]


def convert_pipe_node(node):
    # this funciton all sequence pipe nodes, its not suppose to be recursive


    build_multiple_pipes = lambda node:
        all = [
            get_childs(node |> Map.get("left_node")),
            get_childs(node |> Map.get("right_node"))
        ]
            |> List.flatten()

        first = build_single_pipe(
            all |> Enum.at(0), all |> Enum.at(1)
        )

        [first, all |> Enum.drop(2)]
            |> List.flatten()
            |> Enum.reduce(lambda x, acc:
                build_single_pipe(acc, x)
            )

    case is_pipenode(node |> Map.get("right_node")):
        False -> build_single_pipe(node)
        True -> build_multiple_pipes(node)

def convert_unaryop_node(node):
    value = convert(node |> Map.get("node"))

    tok_type = node |> Map.get("op_tok") |> Map.get("type")
    tok_value = node |> Map.get("op_tok") |> Map.get("value")

    cases = [
        tok_type == "KEYWORD" and tok_value == "not",
        tok_type == "PLUS",
        tok_type == "MINUS"
    ]

    not_case = lambda value:
        Enum.join([
            "{:__block__, [], [{:!, [context: Elixir, import: Kernel], [", value, "]}]}"
        ])

    plus_case = lambda value:
        Enum.join([
            "{:+, [context: Elixir, import: Kernel], [", value, "]}"
        ])

    minus_case = lambda value:
        Enum.join([
            "{:-, [context: Elixir, import: Kernel], [", value, "]}"
        ])

    builder = case cases:
        [True, _, _] -> not_case(value)
        [_, True, _] -> plus_case(value)
        [_, _, True] -> minus_case(value)


def convert_tuple_node(node):
    items = node
        |> Map.get("element_nodes")
        |> Enum.map(&convert/1)
        |> Enum.join(", ")

    Enum.join(["{:{}, [], [", items, "]}"])