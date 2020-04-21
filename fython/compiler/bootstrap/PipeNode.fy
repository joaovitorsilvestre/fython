def convert_pipe_node(node):
    # TODO verify that left_node is not of tipe pipenode
    # this funciton must handle they all, its not suppose to be recursible

    case is_pipenode(node |> Map.get("right_node")):
        False -> build_single_pipe(node)
        True -> build_multiple_pipes(node)

def apply_convert(node):
    Kernel.apply("Elixir.ParserNode" |> String.to_atom(), :convert, [node])

def is_pipenode(node):
    (node |> Map.get("NodeType")) == "PipeNode"


def build_single_pipe(node):
    left = node |> Map.get("left_node") |> apply_convert()
    right = node |> Map.get("right_node") |> apply_convert()
    build_single_pipe(left, right)

def build_single_pipe(left, right):
    left = case is_map(left):
        True -> left |> apply_convert()
        False -> left

    right = right |> apply_convert()

    Enum.join([
        "{:|>, [context: Elixir, import: Kernel], [",
        left, ",", right, "]}", ''
    ], "")

def get_childs(right_or_left_node):
    case is_pipenode(right_or_left_node):
        True -> [
            get_childs(right_or_left_node |> Map.get("left_node")),
            get_childs(right_or_left_node |> Map.get("right_node"))
        ]
        False -> [right_or_left_node]

def build_multiple_pipes(node):
    all = [
        get_childs(node |> Map.get("left_node")),
        get_childs(node |> Map.get("right_node"))
    ]
        |> List.flatten()

    first = build_single_pipe(
        all |> Enum.at(0), all |> Enum.at(1)
    )

    [first, all |> Enum.drop(2)]
        |> List.flatten()
        |> Enum.reduce(lambda x, acc:
            build_single_pipe(acc, x)
        )