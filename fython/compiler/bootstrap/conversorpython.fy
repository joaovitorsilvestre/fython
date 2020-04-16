def convert(json):
    # main function to convert json lexed and parsed in python
    # to fython

    json |> Enum.map(lambda node:
        convert_node(node)
    )

def convert_node(node):
    by_node_type = {
        "StatementsNode": convert_statements_node
    }

    conversor_to_use = by_node_type |> Map.get(node |> Map.get("NodeType"))

def convert_statements_node(node):
    "foiii"
