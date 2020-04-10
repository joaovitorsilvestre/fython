from fython.core.run import run

with open('file.fy') as f:
    lines = f.read()

    result, error = run('<file.fy>', lines)

    if error:
        print(error.as_string())
    elif result:
        print(result if len(result.elements) > 1 else result.elements[0])
