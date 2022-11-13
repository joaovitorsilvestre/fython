def test_lambda():
    a = lambda a, b: a + b
    assert a(10, 15) == 25

    assert Elixir.Enum.map([1, 2, 3], lambda x: x + 1) == [2, 3, 4]
