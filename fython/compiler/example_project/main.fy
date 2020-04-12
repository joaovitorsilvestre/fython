import Map

def calculate(a, b, operation):
    operations = {
        "+": a + b,
        "-": a - b,
        "/": a / b,
        "*": a * b,
    }

    # aqui nós retornamos o role
    operations |> Map.get(operation)