from Main import self/1

def calculate(a, b, operation):
    operations = {
        "+": a + b,
        "-": a - b,
        "/": a / b,
        "*": a * b
    }

    a = 30_000

    list = [1, 2, 3, operations |> Map.get(operation)]

    # aqui nós retornamos o role a =c {{} [] 09090321
    operations
        |> Map.get(operation)
        |> self()
        |> self()
        |> self()

    list
        |> Enum.find(lambda (i):
            i == 2
        )
