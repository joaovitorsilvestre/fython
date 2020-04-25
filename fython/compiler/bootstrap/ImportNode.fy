import Utils

def convert_import_node(node):
    case Map.get(node, "modules_import"):
        None -> "not implemened from"
        _    -> import_case(node)


def import_case(node):
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

            import_command = Utils.join_str([
                "{:import, [context: Elixir], ",
                "[{:__aliases__, [alias: false], ",
                "[", name, "]}]}"
            ])

            result = case Map.get(imp, "alias"):
                None -> import_command
                _ -> Utils.join_str([
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

    Utils.join_str(["{:__block__, [], [", import_commands, "]}"])
