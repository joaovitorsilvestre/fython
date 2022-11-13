def test_tuples():
    assert ((10,) |> Elixir.Kernel.elem(0)) == 10
    assert ((1, 2) |> Elixir.Kernel.elem(0)) == 1
    assert ((1, 2) |> Elixir.Kernel.elem(1)) == 2
