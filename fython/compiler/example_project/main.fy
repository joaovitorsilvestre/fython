import Map

def calculate(a, b, operation):
    operations = {
        "+": a + b,
        "-": a - b,
        "/": a / b,
        "*": a * b
    }

    # aqui nós retornamos o role a =c {{} [] 09090321
    operations
        |> Map.fetch(operation)
