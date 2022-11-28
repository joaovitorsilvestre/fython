def test_range():
    assert Elixir.Enum.to_list(1..5) == [1, 2, 3, 4, 5]
    assert Elixir.Enum.to_list(5..1) == [5, 4, 3, 2, 1]

#def test_range_with_variables():
#    (a, b) = (0, 5)
#    assert a..b == 0..5
#    assert Elixir.Enum.to_list(a..b) == [1, 2, 3, 4, 5]
