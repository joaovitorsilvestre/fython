def oi():
    a = {"a": {"b": {"c": 1}}}

    IO.puts(a |> Map.get("a") |> Map.get("b") |> Map.get("c"))