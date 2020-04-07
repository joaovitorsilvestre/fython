from fython.before_ep6_improves import run

while True:
    text = input('fyton> ')
    if text == ''.strip():
        continue

    result, error = run('<stdin>', text)

    if error:
        print(error.as_string())
    elif result:
        print(result if len(result.elements) > 1 else result.elements[0])