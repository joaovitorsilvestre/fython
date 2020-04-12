import Map

def calculate(a, b, operation):
    operations = {
        "+": a + b,
        "-": a - b,
        "/": a / b,
        "*": a * b,
    }

    operations |> Map.get(operation)