def test_pipe_operator():
    value = [1, 2, 3] |> Elixir.Enum.map(lambda x: x * -1)
    assert value == [-1, -2, -3]