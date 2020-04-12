from Main import self/1

def calculate(a, b, operation):
    operations = {
        "+": a + b,
        "-": a - b,
        "/": a / b,
        "*": a * b
    }

    list = [1, 2, 3, operations |> Map.get(operation)]

    # aqui nós retornamos o role a =c {{} [] 09090321
    #operations
    #    |> Map.get(operation)
    #    |> self()
    #    |> self()
    #    |> self()

    list
        |> Enum.find(def (i):
            i == 2
        )

