def run_tests():
    basic_operations()

def basic_operations():
    assert(1 + 2, 3)

def assert(a, b):
    Elixir.IO.inspect("assert " + a + " equals " + b)
    case a == b:
        True -> raise "Diferente"
        False -> None