import Utils

def convert_call_node(convert, node):
    args = node
        |> Map.get("arg_nodes")
        # TODO we dont have support for: Enum.map(&convert/1)
        |> Enum.map(lambda i: convert(i))

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
        Map.get(node, "local_call"),
        Map.get(node, "name", "") |> String.contains?(".")
    ]

    case cases:
        [True, _] -> local_call_case(func_name, arguments)
        [_, True] -> module_function_call_case(
            func_name, node |> Map.get("arity"), arguments
        )
        _         -> Enum.join(["{:", func_name, ", [], ", arguments, "}"])

def local_call_case(func_name, arguments):
    Utils.join_str([
        "{{:., [], [{:", func_name, ", [], Elixir}]}, [], ", arguments, "}"
    ])

def module_function_call_case(name, arity, arguments):
    module = name |> String.split(".") |> List.pop_at(-1)
    function = name |> String.split(".") |> Enum.at(-1)

    Enum.join([
        "{{:., [], [{:__aliases__, [alias: false], [:",
        module,
        "]}, :",
        function,
        "]}, [], ",
        arguments,
        "}"
    ], '')
