from fython.ep4 import run

while True:
    text = input('fyton> ')

    result, error = run('<stdin>', text)

    if error:
        print(error.as_string())
    else:
        print(result)