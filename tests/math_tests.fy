def run_tests():
    basic_operations()

def basic_operations():
    assert_equal(1 + 2, 3)


def assert_equal(a, b):
    case a == b:
        False -> raise "Diferente"
        True -> None