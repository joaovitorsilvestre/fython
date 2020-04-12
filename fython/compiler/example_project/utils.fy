from Main import self/1

def calculate(a, b, operation):
    operations = {
        "+": a + b,
        "-": a - b,
        "/": a / b,
        "*": a * b
    }

    list = [1, 2, 3, operations |> Map.get(operation)]

    list
        |> Enum.find(def (i):
            i
        )

    # aqui nós retornamos o role a =c {{} [] 09090321
    #operations
    #    |> Map.get(operation)
    #    |> self()
    #    |> self()
    #    |> self()

