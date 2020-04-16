def convert(json):
    # main function to convert json lexed and parsed in python
    # to fython

    json |> Enum.map(lambda node:
        convert_node(node)
    )

def convert_node(node):
    func = case Map.get(node, "NodeType"):
        "StatementsNode" -> lambda: convert_statements_node(node)
        _ -> 2

    func()

def convert_statements_node(node):
    "foiii"
