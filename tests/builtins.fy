def test_enumerate():
    assert Elixir.Enum.to_list(enumerate(["a", "b"])) == [(0, "a"), (1, "b")]
    assert Elixir.Enum.to_list(enumerate({"a": None, "b": None})) == [(0, "a"), (1, "b")]
    assert Elixir.Enum.to_list(enumerate(10..13)) == [(0, 10), (1, 11), (2, 12), (3, 13)]

def test_len():
    assert len([1, 2, 3]) == 3
    assert len("abcde") == 5
