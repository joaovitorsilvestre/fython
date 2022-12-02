def test_charlist():
    assert c"abc" == Elixir.List.Chars.to_charlist("abc")