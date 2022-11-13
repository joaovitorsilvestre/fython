def test_lists():
    a = [1, 2, 3]
    assert Elixir.Enum.at(a, 0) == 1
    assert Elixir.Enum.at(a, 1) == 2
    assert Elixir.Enum.at(a, 2) == 3