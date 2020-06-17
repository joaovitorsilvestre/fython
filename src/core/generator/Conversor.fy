def convert(node):
    # TEMP FIX WHILE WE DONT CONVERT ALL NODES TO NEW AST
    case Elixir.Map.get(node, '_new'):
        None ->
            case Elixir.Map.get(node, "NodeType"):
                "TryNode"           -> convert_try_node(node)
        _ ->
            Core.Generator.Newconversor.convert(node['_new'])

def meta(node):
    Elixir.Enum.join(['[line: ', node['pos_start']['ln'], "]"])

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
