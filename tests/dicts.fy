def test_dicts():
    a = {'a': 2}
    assert a['a'] == 2

    a = Elixir.Map.put(a, 'b', 20)
    assert a['b'] == 20
    assert a == {"a": 2, 'b': 20}

    key = 50
    a = {key: "a"}
    assert a[50] == "a"
