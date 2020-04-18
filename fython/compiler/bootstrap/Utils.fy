def join_str(list):
    list |> Enum.map(lambda i: i |> to_string()) |> Enum.join('')
