from fython.before_ep6_improves import run

while True:
    text = input('fyton> ')

    result, error = run('<stdin>', text)

    if error:
        print(error.as_string())
    elif result:
        print(result)