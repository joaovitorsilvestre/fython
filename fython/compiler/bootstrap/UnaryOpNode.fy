import Utils

def convert_unaryop_node(convert, node):
    value = convert(node |> Map.get("node"))

    tok_type = node |> Map.get("op_tok") |> Map.get("type")
    tok_value = node |> Map.get("op_tok") |> Map.get("value")

    cases = [
        tok_type == "KEYWORD" and tok_value == "not",
        tok_type == "PLUS",
        tok_type == "MINUS"
    ]

    builder = case cases:
        [True, _, _] -> not_case(value)
        [_, True, _] -> plus_case(value)
        [_, _, True] -> minus_case(value)


def not_case(value):
    Utils.join_str([
        "{:__block__, [], [{:!, [context: Elixir, import: Kernel], [", value, "]}]}"
    ])

def plus_case(value):
    Utils.join_str([
        "{:+, [context: Elixir, import: Kernel], [", value, "]}"
    ])

def minus_case(value):
    Utils.join_str([
        "{:-, [context: Elixir, import: Kernel], [", value, "]}"
    ])
