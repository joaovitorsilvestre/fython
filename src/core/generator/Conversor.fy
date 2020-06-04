def convert(node):
    # TEMP FIX WHILE WE DONT CONVERT ALL NODES TO NEW AST
    case Elixir.Map.get(node, '_new'):
        None ->
            case Elixir.Map.get(node, "NodeType"):
                "StatementsNode"    -> convert_statements_node(node)
                "PatternMatchNode"  -> convert_patternmatch_node(node)
                "IfNode"            -> convert_if_node(node)
                "UnaryOpNode"       -> convert_unaryop_node(node)
                "FuncDefNode"       -> convert_deffunc_node(node)
                "LambdaNode"        -> convert_lambda_node(node)
                "CallNode"          -> convert_call_node(node)
                "PipeNode"          -> convert_pipe_node(node)
                "MapNode"           -> convert_map_node(node)
                "ImportNode"        -> convert_import_node(node)
                "CaseNode"          -> convert_case_node(node)
                "RaiseNode"         -> convert_raise_node(node)
                "StaticAccessNode"  -> convert_staticaccess_node(node)
                "TryNode"           -> convert_try_node(node)
                "FuncAsVariableNode" -> convert_funcasvariable_node(node)
        _ ->
            Core.Generator.Newconversor.convert(node['_new'])

def meta(node):
    Elixir.Enum.join(['[line: ', node['pos_start']['ln'], "]"])

def convert_patternmatch_node(node):
    left = Elixir.Map.get(node, 'left_node') |> convert()
    right = Elixir.Map.get(node, 'right_node') |> convert()

    Elixir.Enum.join([
        "{:=, ",
        meta(node), ", ",
        "[", left , ", ", right , "]",
        "}"
    ])

def convert_if_node(node):
    comp_expr = convert(node |> Elixir.Map.get("comp_expr"))
    true_case = convert(node |> Elixir.Map.get("true_case"))
    false_case = convert(node |> Elixir.Map.get("false_case"))

    Elixir.Enum.join([
        "{:if, ", meta(node), ", [",
        comp_expr,
        ", [do: ",
        true_case,
        ", else: ",
        false_case,
        "]]}"
    ])

def convert_lambda_node(node):
    params = node
        |> Elixir.Map.get("arg_nodes")
        |> Elixir.Enum.map(&convert/1)
        |> Elixir.Enum.join(", ")

    params = ['[', params, ']'] |> Elixir.Enum.join('')

    Elixir.Enum.join([
        "{:fn, ", meta(node), ", [{:->, ", meta(node), ", [",
        params,
        ", ",
        convert(node |> Elixir.Map.get('body_node')),
        "]}]}"
    ])

def convert_map_node(node):
    pairs = node
        |> Elixir.Map.get("pairs_list")
        |> Elixir.Enum.map(lambda pair:
            [key, value] = pair
            Elixir.Enum.join(["{", convert(key), ", ", convert(value), "}"])
        )
        |> Elixir.Enum.join(', ')

    r = Elixir.Enum.join(["{:%{}, ", meta(node), ", [", pairs, "]}"])

def convert_statements_node(node):
    content = node
        |> Elixir.Map.get("statement_nodes")
        |> Elixir.Enum.map(lambda i: convert(i))

    case Elixir.Enum.count(content):
        1 -> Elixir.Enum.at(content, 0)
        _ -> Elixir.Enum.join([
            '{:__block__, ', meta(node), ', [', Elixir.Enum.join(content, ', '), ']}'
        ])

def convert_deffunc_node(node):
    name = node |> Elixir.Map.get("var_name_tok") |> Elixir.Map.get("value")
    statements_node = node |> Elixir.Map.get("body_node")

    arguments = node
        |> Elixir.Map.get("arg_nodes")
        |> Elixir.Enum.map(&convert/1)
        |> Elixir.Enum.join(', ')

    Elixir.Enum.join([
        "{:def, ", meta(node), ", [{:", name, ", ", meta(node),", [",
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
                "{:->, ", meta(node), ", [[", convert(left), "], ", convert(right), "]}"
            ], '')
        )
        |> Elixir.Enum.join(', ')

    case expr:
        None -> Elixir.Enum.join([
                "{:cond, ", meta(node), ", [[do: [", arguments, "]]]}"
            ])
        _ -> Elixir.Enum.join([
                "{:case, ", meta(node), ", [", expr, ", [do: [", arguments, "]]]}"
            ])

def convert_raise_node(node):
    expr = Elixir.Map.get(node, "expr") |> convert()

    Elixir.Enum.join(["{:raise, ", meta(node), ", [", expr, "]}"])

def convert_funcasvariable_node(node):
    name = node |> Elixir.Map.get("var_name_tok") |> Elixir.Map.get("value")
    arity = node |> Elixir.Map.get("arity")
    Elixir.Enum.join([
        "{:&, ", meta(node), ", [{:/, ", meta(node), ", [{:",
        name, ", ", meta(node), ", Elixir}, ", arity, "]}]}"
    ])

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
            Elixir.Enum.join(["{{:., ", meta(node), ", [", func_to_call, "]}, ", meta(node), ", ", arguments, "}"])
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

                    module = case:
                        Elixir.String.starts_with?(module, "Elixir.") -> module
                        Elixir.String.starts_with?(module, "Erlang.") ->
                            Elixir.Enum.join([':"', Elixir.String.replace(module, "Erlang.", ""), '"'])
                        True -> Elixir.Enum.join([':"Fython.', module, '"'])

                    Elixir.Enum.join(["{{:., ", meta(node), ", [", module, ", :", function, "]}, ", meta(node), ", ", arguments, "}"])
                False ->
                    # this is for call a function that is defined in
                    # the same module
                    Elixir.Enum.join(["{:", func_name, ", ", meta(node), ", ", arguments, "}"])

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
                        "{:import, ", meta(node), ", ",
                        "[{:__aliases__, [alias: false], ",
                        "[", name, "]}]}"
                    ])

                    result = case Elixir.Map.get(imp, "alias"):
                        None -> import_command
                        _ -> Elixir.Enum.join([
                            "{:__block__, ", meta(node), ", [",
                                import_command,
                                ", {:alias, ", meta(node), ", [",
                                "{:__aliases__, [alias: false], [", name, "]},",
                                "[as: {:__aliases__, [alias: ", name, "], [:", alias,"]}]",
                                "]}",
                            "]}"
                        ])
                    result
                )
                |> Elixir.Enum.join(', ')

            Elixir.Enum.join(["{:__block__, ", meta(node), ", [", import_commands, "]}"])


def get_childs(right_or_left_node):
    case Elixir.Map.get(right_or_left_node, "NodeType") == "PipeNode":
        True -> [
            get_childs(right_or_left_node |> Elixir.Map.get("left_node")),
            get_childs(right_or_left_node |> Elixir.Map.get("right_node"))
        ]
        False -> [right_or_left_node]

def convert_pipe_node(node):
    # Actually, we never convert to elixir pipe ast
    # Instead, we do elixier job to put the left node of the pipe
    # as the first parameter of the right node
    # We do this because elixir pipe ast doesnt work well
    # with a erlang call in the right. Eg: "oii" |> :string.replace("o", "i")

    left_node = Elixir.Map.get(node, 'left_node')
    right_node = Elixir.Map.get(node, 'right_node')

    ([first], flat_pipe) = left_node
        |> get_childs()
        |> Elixir.List.insert_at(-1, get_childs(right_node))
        |> Elixir.List.flatten()
        |> Elixir.Enum.split(1)

    call_node = Elixir.Enum.reduce(
        flat_pipe,
        first,
        lambda c_node, acc:
            {"arg_nodes": arg_nodes, "arity": arity} = c_node

            c_node
                |> Elixir.Map.put("arity", arity + 1)
                |> Elixir.Map.put("arg_nodes", Elixir.List.insert_at(arg_nodes, 0, acc))
    )

    convert(call_node)


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
            "{:__block__, ", meta(node), ", [{:!, ", meta(node), ", [", value, "]}]}"
        ])

    plus_case = lambda value:
        Elixir.Enum.join([
            "{:+, ", meta(node), ", [", value, "]}"
        ])

    minus_case = lambda value:
        Elixir.Enum.join([
            "{:-, ", meta(node), ", [", value, "]}"
        ])

    builder = case cases:
        [True, _, _] -> not_case(value)
        [_, True, _] -> plus_case(value)
        [_, _, True] -> minus_case(value)

def convert_staticaccess_node(node):
    to_be_accesed = convert(Elixir.Map.get(node, "node"))
    value_to_find = convert(Elixir.Map.get(node, "node_value"))

    Elixir.Enum.join([
        "{{:., ", meta(node), ", [{:__aliases__, [alias: false], [:Map]}, :fetch!]}, ", meta(node), ", [",
        to_be_accesed, ", ", value_to_find, "]}"
    ])

def convert_try_node(node):
    do = Elixir.Enum.join([
        "{:do, ", convert(node['try_block_node']), "}"
    ])

    each_rescue = Elixir.Enum.map(
        node['exceptions'],
        lambda i :
            (except_expr, alias, block) = i

            case alias:
                None -> Elixir.Enum.join([
                    "{:->, ", meta(node), ", [[{:__aliases__, [alias: false], [:",
                    except_expr, "]}], ", convert(block), "]}"
                ])
                _ -> Elixir.Enum.join([
                    "{:->, ", meta(node), ",", "[[",
                    "{:in, ", meta(node), ",",
                    "[{:", alias, ", ", meta(node), ", Elixir}, {:__aliases__, [alias: false], [:", except_expr, "]}]}",
                    "],", convert(block), "]}"
                ])
    )

    each_rescue = Elixir.Enum.join(each_rescue, ", ")

    rescue = Elixir.Enum.join([
        "{:rescue, [", each_rescue, "]}"
    ])

    Elixir.Enum.join([
        "{:try, ", meta(node), ", [[", do, ", ", rescue, "]]}"
    ])
