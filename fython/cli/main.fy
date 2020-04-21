import Utils

def compile(path):
    a = {"a": {"b": {"c": 1}}}

    a
        |> Map.get("a")
        |> Map.get("b")
        |> Map.get("c")
        |> IO.inspect()

    [a, Utils.Printer.print(1)]