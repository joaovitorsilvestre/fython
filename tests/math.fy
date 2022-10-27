def run_tests():
    basic_operations()

def basic_operations():
    assert(1 + 2, 3)

def assert(a, b):
    case a == b:
        False -> raise "Diferente"
        True -> None