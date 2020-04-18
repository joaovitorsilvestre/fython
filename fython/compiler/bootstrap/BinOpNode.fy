import Utils

def convert_binop_node(convert, node):
    IO.inspect(convert)

    #a = convert(Map.get(node, "left_node"))
    #b = convert(Map.get(node, "right_node"))

    #simple_ops = [
    #    #'+', '-', '*', '/', '>', '>=', '<', '<=', '=='
    #]

    #tok_type = node |> Map.get("op_tok") |> Map.get("type")
    #tok_value = node |> Map.get("op_tok") |> Map.get("value")

    #cases = [
    #    #List.member?(tok_type, simple_ops),
    #    #tok_type == "**",
    #    #tok_type == "KEYWORD" and tok_value == "or",
    #    #tok_type == "KEYWORD" and tok_value == "and"
    #]

    #a = case cases:
    #    #[True, _, _] -> lambda: simple_op_node(simple_ops, node, a, b)
    #    #[_, True, _] -> lambda: or_op(node, a, b)
    #    #[_, _, True] -> lambda: and_op(node, a, b)
    #a()


def simple_op_node(simple_ops, node, a, b):
    op = simple_ops |> Map.get(node |> Map.get("op_tok") |> Map.get("type"))
    Utils.join_str([
        "{:", op, ", [context: Elixir, import: Kernel], [", a, ", ", b, "]}"
    ])

def or_op(node, a, b):
    Utils.join_str([
        "{:or, [context: Elixir, import: Kernel], [", a, ", ", b, "]}"
    ])

def and_op(node, a, b):
    Utils.join_str([
        "{:adn, [context: Elixir, import: Kernel], [", a, ", ", b, "]}"
    ])
