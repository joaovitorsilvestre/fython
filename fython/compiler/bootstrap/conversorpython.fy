def convert(json):
    # main function to convert json lexed and parsed in python
    # to fython
    convert_node(json)

def convert_node(node):

    func = case Map.get(node, "NodeType"):
        "StatementsNode" -> lambda: convert_statements_node(node)
        _ -> 2

    func()

def convert_statements_node(node):
    IO.inspect(node)
    "foiii"
