def convert(item):
    None

def convert_unaryop_node(node):
    value = convert(node |> Map.get("node"))

    tok_type = node |> Map.get("op_tok") |> Map.get("type")
    tok_value = node |> Map.get("op_tok") |> Map.get("value")

    not_case = lambda value:
        Enum.join([
            "{:__block__, [], [{:!, [context: Elixir, import: Kernel], [", value, "]}]}"
        ])

    builder = case []:
        [True, _, _] -> not_case(value)
