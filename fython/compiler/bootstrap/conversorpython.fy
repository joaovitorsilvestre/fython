def convert(json):
    # main function to convert json lexed and parsed in python
    # to fython

    json |> Enum.map(lambda node:
        convert_node(node)
    )

def convert_node(node):
    case Map.get(node, "NodeType"):
        "StatementsNode" -> 1
        _ -> 2

def convert_statements_node(node):
    "foiii"
