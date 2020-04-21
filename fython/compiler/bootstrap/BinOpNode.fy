import Utils

def convert_binop_node(convert, node):
    a = convert(Map.get(node, "left_node"))
    b = convert(Map.get(node, "right_node"))

    simple_ops = {
        "PLUS": '+', "MINUS": '-', "MUL": '*', "DIV": '/',
        "GT": '>', "GTE": '>=', "LT": '<', "LTE": '<=',
        "EE": '==', 'NE': '!='
    }

    tok_type = node |> Map.get("op_tok") |> Map.get("type")
    tok_value = node |> Map.get("op_tok") |> Map.get("value")

    cases = [
        Map.has_key?(simple_ops, tok_type),
        tok_type == "POW",
        tok_type == "KEYWORD" and tok_value == "or",
        tok_type == "KEYWORD" and tok_value == "and"
    ]

    case cases:
        [True, _, _, _] -> simple_op_node(simple_ops, node, a, b)
        [_, True, _, _] -> power_op(a, b)
        [_, _,True, _]  -> or_op(a, b)
        [_, _, _,True]  -> and_op(a, b)


def simple_op_node(simple_ops, node, a, b):
    op = simple_ops |> Map.get(node |> Map.get("op_tok") |> Map.get("type"))
    Utils.join_str([
        "{:", op, ", [context: Elixir, import: Kernel], [", a, ", ", b, "]}"
    ])

def power_op(a, b):
    Utils.join_str([
        "{{:., [], [:math, :pow]}, [], [", a, ", ", b, "]}"
    ])

def or_op(a, b):
    Utils.join_str([
        "{:or, [context: Elixir, import: Kernel], [", a, ", ", b, "]}"
    ])

def and_op(a, b):
    Utils.join_str([
        "{:and, [context: Elixir, import: Kernel], [", a, ", ", b, "]}"
    ])
