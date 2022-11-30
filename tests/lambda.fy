def test_lambda():
    a = lambda a, b: a + b
    assert a(10, 15) == 25

    assert Elixir.Enum.map([1, 2, 3], lambda x: x + 1) == [2, 3, 4]

def test_lambda_call_local():
    sum = lambda a, b: a + b
    state = {"callback": sum}
    assert state["callback"](1, 2) == 3

    sub = lambda a, b: a - b
    assert sub(1, 2) == -1
