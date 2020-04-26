def statements_node(nodes_list):
    pos_start = nodes_list |> Enum.at(0) |> Map.get("pos_start")
    pos_end = nodes_list |> Enum.at(-1) |> Map.get("pos_end")

    {
        "statement_nodes": nodes_list,
        "pos_start": pos_start,
        "pos_end": pos_end
    }
