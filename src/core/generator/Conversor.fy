def convert(node):
    # TEMP FIX WHILE WE DONT CONVERT ALL NODES TO NEW AST
    case Elixir.Map.get(node, '_new'):
        None ->
            case Elixir.Map.get(node, "NodeType"):
                "CallNode"          -> convert_call_node(node)
                "CaseNode"          -> convert_case_node(node)
                "TryNode"           -> convert_try_node(node)
        _ ->
            Core.Generator.Newconversor.convert(node['_new'])

def meta(node):
    Elixir.Enum.join(['[line: ', node['pos_start']['ln'], "]"])

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
