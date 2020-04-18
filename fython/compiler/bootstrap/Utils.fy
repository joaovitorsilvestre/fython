def join_str(list):
    Enum.map(list, lambda i: to_string(i)) |> Enum.join("")
