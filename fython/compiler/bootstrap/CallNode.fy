import Utils

def convert_call_node(convert, node):
    args = node
        |> Map.get("arg_nodes")
        |> Enum.map(convert)

    keywords = node
        |> Map.get("keywords")
        |> Map.to_list()
        |> Enum.map(lambda k_v:
            k = elem(k_v, 0)
            v = elem(k_v, 1)
            Utils.join_str(["[", k, ": ", convert(v), "]"])
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

    case cases:
        [True, _] -> module_function_call_case(func_name, arguments)
        [_, True] -> local_call_case(func_name, arguments)
        _         -> Enum.join(["{:", func_name, ", [], ", arguments, "}"])

def local_call_case(func_name, arguments):
    Utils.join_str([
        "{{:., [], [{:", func_name, ", [], Elixir}]}, [], ", arguments, "}"
    ])

def module_function_call_case(name,  arguments):
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
