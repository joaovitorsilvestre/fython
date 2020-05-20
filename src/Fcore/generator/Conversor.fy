def convert(node):
    func = case Elixir.Map.get(node, "NodeType"):
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
        "StaticAccessNode"  -> convert_staticaccess_node(node)
        "FuncAsVariableNode" -> convert_funcasvariable_node(node)

def convert_number_node(node):
    node |> Elixir.Map.get("tok") |> Elixir.Map.get("value") |> Elixir.Kernel.to_string()

def convert_atom_node(node):
    Elixir.Enum.join([":", node |> Elixir.Map.get("tok") |> Elixir.Map.get("value")])

def convert_string_node(node):
    value = node
        |> Elixir.Map.get("tok")
        |> Elixir.Map.get("value")

    # We need to remove this dependency, eventually
    # Convert to json is te easiest way that we found for scape
    # `"` and `/` (and probably another chars too)
    Elixir.Enum.join(['"', value ,'"'])

def convert_varaccess_node(node):
    tok_value = node |> Elixir.Map.get("var_name_tok") |> Elixir.Map.get("value")

    pinned = Elixir.Map.get(node, "pinned")

    pin_node = lambda i: Elixir.Enum.join(["{:^, [], [", i, "]}"]) if pinned else i

    case:
        tok_value == "True" -> "true"
        tok_value == "False" -> "false"
        tok_value == "None" -> "nil"
        True -> Elixir.Enum.join(["{:", tok_value, ", [], Elixir}"]) |> pin_node()

def convert_patternmatch_node(node):
    left = Elixir.Map.get(node, 'left_node') |> convert()
    right = Elixir.Map.get(node, 'right_node') |> convert()

    Elixir.Enum.join([
        "{:=, ",
        "[], ",
        "[", left , ", ", right , "]",
        "}"
    ])

def convert_if_node(node):
    comp_expr = convert(node |> Elixir.Map.get("comp_expr"))
    true_case = convert(node |> Elixir.Map.get("true_case"))
    false_case = convert(node |> Elixir.Map.get("false_case"))

    Elixir.Enum.join([
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
        |> Elixir.Map.get("arg_name_toks")
        |> Elixir.Enum.map(lambda param:
            Elixir.Enum.join([
                "{:",
                param |> Elixir.Map.get('value'),
                ", [context: Elixir, import: IEx.Helpers], Elixir}"
            ])
        )
        |> Elixir.Enum.join(", ")

    params = ['[', params, ']'] |> Elixir.Enum.join('')

    Elixir.Enum.join([
        "{:fn, [], [{:->, [], [",
        params,
        ", ",
        convert(node |> Elixir.Map.get('body_node')),
        "]}]}"
    ])

def convert_list_node(node):
    Elixir.Enum.join([
        "[",
        Elixir.Enum.join(Elixir.Enum.map(node |> Elixir.Map.get("element_nodes"), &convert/1), ", "),
        "]"
    ])

def convert_map_node(node):
    pairs = node
        |> Elixir.Map.get("pairs_list")
        |> Elixir.Enum.map(lambda pair:
            [key, value] = pair
            Elixir.Enum.join(["{", convert(key), ", ", convert(value), "}"])
        )
        |> Elixir.Enum.join(', ')

    r = Elixir.Enum.join(["{:%{}, [], [", pairs, "]}"])

def convert_statements_node(node):
    content = node
        |> Elixir.Map.get("statement_nodes")
        |> Elixir.Enum.map(lambda i: convert(i))

    case Elixir.Enum.count(content):
        1 -> Elixir.Enum.at(content, 0)
        _ -> Elixir.Enum.join([
            '{:__block__, [line: 0], [', Elixir.Enum.join(content, ', '), ']}'
        ])

def convert_deffunc_node(node):
    name = node |> Elixir.Map.get("var_name_tok") |> Elixir.Map.get("value")
    statements_node = node |> Elixir.Map.get("body_node")

    arguments = node
        |> Elixir.Map.get("arg_name_toks")
        |> Elixir.Enum.map(lambda argument:
            Elixir.Enum.join(["{:", Elixir.Map.get(argument, "value"), ", [], Elixir}"])
        )
        |> Elixir.Enum.join(', ')

    Elixir.Enum.join([
        "{:def, [line: 0], [{:", name, ", [line: 0], [",
        arguments, "]}, [do: ", convert(statements_node), "]]}"
    ])

def convert_case_node(node):
    expr = convert(node |> Elixir.Map.get("expr")) if node |> Elixir.Map.get("expr") else None

    arguments = node
        |> Elixir.Map.get("cases")
        |> Elixir.Enum.map(lambda left_right:
            left = Elixir.Enum.at(left_right, 0)
            right = Elixir.Enum.at(left_right, 1)

            Elixir.Enum.join([
                "{:->, [], [[", convert(left), "], ", convert(right), "]}"
            ], '')
        )
        |> Elixir.Enum.join(', ')

    case expr:
        None -> Elixir.Enum.join([
                "{:cond, [], [[do: [", arguments, "]]]}"
            ])
        _ -> Elixir.Enum.join([
                "{:case, [], [", expr, ", [do: [", arguments, "]]]}"
            ])

def convert_in_node(node):
    left = Elixir.Map.get(node, "left_expr") |> convert()
    right = Elixir.Map.get(node, "right_expr") |> convert()

    Elixir.Enum.join([
        "{:in, [context: Elixir, import: Kernel], [", left, ", ", right, "]}"
    ])

def convert_raise_node(node):
    expr = Elixir.Map.get(node, "expr") |> convert()

    Elixir.Enum.join(["{:raise, [context: Elixir, import: Kernel], [", expr, "]}"])

def convert_funcasvariable_node(node):
    name = node |> Elixir.Map.get("var_name_tok") |> Elixir.Map.get("value")
    arity = node |> Elixir.Map.get("arity")
    Elixir.Enum.join([
        "{:&, [], [{:/, [context: Elixir, import: Kernel], [{:",
        name, ", [], Elixir}, ", arity, "]}]}"
    ])

def convert_binop_node(node):
    a = convert(Elixir.Map.get(node, "left_node"))
    b = convert(Elixir.Map.get(node, "right_node"))

    simple_ops = {
        "PLUS": '+', "MINUS": '-', "MUL": '*', "DIV": '/',
        "GT": '>', "GTE": '>=', "LT": '<', "LTE": '<=',
        "EE": '==', 'NE': '!='
    }

    tok_type = node |> Elixir.Map.get("op_tok") |> Elixir.Map.get("type")
    tok_value = node |> Elixir.Map.get("op_tok") |> Elixir.Map.get("value")

    cases = [
        Elixir.Map.has_key?(simple_ops, tok_type),
        tok_type == "POW",
        tok_type == "KEYWORD" and tok_value == "or",
        tok_type == "KEYWORD" and tok_value == "and"
    ]

    simple_op_node = lambda simple_ops, node, a, b:
        op = simple_ops |> Elixir.Map.get(node |> Elixir.Map.get("op_tok") |> Elixir.Map.get("type"))
        Elixir.Enum.join([
            "{:", op, ", [context: Elixir, import: Kernel], [", a, ", ", b, "]}"
        ])

    power_op = lambda a, b:
        Elixir.Enum.join([
            "{{:., [], [:math, :pow]}, [], [", a, ", ", b, "]}"
        ])

    or_op = lambda a, b:
        Elixir.Enum.join([
            "{:or, [context: Elixir, import: Kernel], [", a, ", ", b, "]}"
        ])

    and_op = lambda a, b:
        Elixir.Enum.join([
            "{:and, [context: Elixir, import: Kernel], [", a, ", ", b, "]}"
        ])

    case cases:
        [True, _, _, _] -> simple_op_node(simple_ops, node, a, b)
        [_, True, _, _] -> power_op(a, b)
        [_, _,True, _]  -> or_op(a, b)
        [_, _, _,True]  -> and_op(a, b)


def convert_call_node(node):
    args = node
        |> Elixir.Map.get("arg_nodes")
        |> Elixir.Enum.map(&convert/1)

    keywords = node
        |> Elixir.Map.get("keywords")
        |> Elixir.Map.to_list()
        |> Elixir.Enum.map(lambda k_v:
            k = Elixir.Kernel.elem(k_v, 0)
            v = Elixir.Kernel.elem(k_v, 1)
            Elixir.Enum.join(["[", k, ": ", convert(v), "]"])
        )

    arguments = Elixir.Enum.join([
        "[",
        [args, keywords] |> Elixir.List.flatten() |> Elixir.Enum.join(", "),
        "]"
    ], "")

    case Elixir.Map.get(node, "local_call"):
        True ->
            func_to_call = convert(Elixir.Map.get(node, "node_to_call"))
            Elixir.Enum.join(["{{:., [], [", func_to_call, "]}, [], ", arguments, "}"])
        False ->
            # node_to_call will always be a VarAccessNode on a module call. E.g: Elixir.Map.get
            func_name = node
                |> Elixir.Map.get("node_to_call")
                |> Elixir.Map.get("var_name_tok")
                |> Elixir.Map.get("value")

            case Elixir.String.contains?(func_name, '.'):
                True ->
                    modules = func_name |> Elixir.String.split(".") |> Elixir.List.pop_at(-1) |> Elixir.Kernel.elem(1)
                    function = func_name |> Elixir.String.split(".") |> Elixir.Enum.at(-1)

                    # for fython modules we need to use the elixir
                    # syntax for erlang calls. Doing this way, we prevent
                    # Elixer compiler from adding 'Elixir.' to module name to call

                    module = Elixir.Enum.join(modules, ".")

                    Elixir.Enum.join(["{{:., [], [", module, ", :", function, "]}, [], ", arguments, "}"])
                False ->
                    # this is for call a function that is defined in
                    # the same module
                    Elixir.Enum.join(["{:", func_name, ", [], ", arguments, "}"])

def convert_import_node(node):
    case Elixir.Map.get(node, "modules_import"):
        None -> "not implemened from"
        _    ->
            import_commands = node
                |> Elixir.Map.get("modules_import")
                |> Elixir.Enum.map(lambda imp:
                    name = Elixir.Map.get(imp, "name")
                    alias = Elixir.Map.get(imp, "alias")

                    case Elixir.String.contains?(name, "."):
                        True ->
                            name = name
                                |> Elixir.String.split(".")
                                |> Elixir.Enum.map(lambda i: Elixir.Enum.join([':', i]))
                                |> Elixir.Enum.join(', ')
                        False -> Elixir.Enum.join([':', name])

                    import_command = Elixir.Enum.join([
                        "{:import, [context: Elixir], ",
                        "[{:__aliases__, [alias: false], ",
                        "[", name, "]}]}"
                    ])

                    result = case Elixir.Map.get(imp, "alias"):
                        None -> import_command
                        _ -> Elixir.Enum.join([
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
                |> Elixir.Enum.join(', ')

            Elixir.Enum.join(["{:__block__, [], [", import_commands, "]}"])

def build_single_pipe(node):
    left = node |> Elixir.Map.get("left_node") |> convert()
    right = node |> Elixir.Map.get("right_node") |> convert()
    build_single_pipe(left, right)

def build_single_pipe(left, right):
    left = case Elixir.Kernel.is_map(left):
        True -> left |> convert()
        False -> left

    right = case Elixir.Kernel.is_map(right):
        True -> right |> convert()
        False -> right

    Elixir.Enum.join([
        "{:|>, [context: Elixir, import: Kernel], [",
        left, ",", right, "]}", ''
    ], "")

def is_pipenode(node):
    (node |> Elixir.Map.get("NodeType")) == "PipeNode"

def get_childs(right_or_left_node):
    case is_pipenode(right_or_left_node):
        True -> [
            get_childs(right_or_left_node |> Elixir.Map.get("left_node")),
            get_childs(right_or_left_node |> Elixir.Map.get("right_node"))
        ]
        False -> [right_or_left_node]


def convert_pipe_node(node):
    # this funciton all sequence pipe nodes, its not suppose to be recursive


    build_multiple_pipes = lambda node:
        all = [
            get_childs(node |> Elixir.Map.get("left_node")),
            get_childs(node |> Elixir.Map.get("right_node"))
        ]
            |> Elixir.List.flatten()

        first = build_single_pipe(
            all |> Elixir.Enum.at(0), all |> Elixir.Enum.at(1)
        )

        [first, all |> Elixir.Enum.drop(2)]
            |> Elixir.List.flatten()
            |> Elixir.Enum.reduce(lambda x, acc:
                build_single_pipe(acc, x)
            )

    case is_pipenode(node |> Elixir.Map.get("right_node")):
        False -> build_single_pipe(node)
        True -> build_multiple_pipes(node)

def convert_unaryop_node(node):
    value = convert(node |> Elixir.Map.get("node"))

    tok_type = node |> Elixir.Map.get("op_tok") |> Elixir.Map.get("type")
    tok_value = node |> Elixir.Map.get("op_tok") |> Elixir.Map.get("value")

    cases = [
        tok_type == "KEYWORD" and tok_value == "not",
        tok_type == "PLUS",
        tok_type == "MINUS"
    ]

    not_case = lambda value:
        Elixir.Enum.join([
            "{:__block__, [], [{:!, [context: Elixir, import: Kernel], [", value, "]}]}"
        ])

    plus_case = lambda value:
        Elixir.Enum.join([
            "{:+, [context: Elixir, import: Kernel], [", value, "]}"
        ])

    minus_case = lambda value:
        Elixir.Enum.join([
            "{:-, [context: Elixir, import: Kernel], [", value, "]}"
        ])

    builder = case cases:
        [True, _, _] -> not_case(value)
        [_, True, _] -> plus_case(value)
        [_, _, True] -> minus_case(value)


def convert_tuple_node(node):
    items = node
        |> Elixir.Map.get("element_nodes")
        |> Elixir.Enum.map(&convert/1)
        |> Elixir.Enum.join(", ")

    Elixir.Enum.join(["{:{}, [], [", items, "]}"])

def convert_staticaccess_node(node):
    to_be_accesed = convert(Elixir.Map.get(node, "node"))
    value_to_find = convert(Elixir.Map.get(node, "node_value"))

    Elixir.Enum.join([
        "{{:., [], [{:__aliases__, [alias: false], [:Map]}, :fetch!]}, [], [",
        to_be_accesed, ", ", value_to_find, "]}"
    ])


