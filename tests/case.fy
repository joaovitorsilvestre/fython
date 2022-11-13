def test_case():
    a = case True:
        True -> "s"
        False -> "n"
    assert a ==  "s"

    a = case {"a": 20}:
        {"a": 10} -> True
        _ -> False
    assert a ==  False

    a = case {"a": 20}:
        {"a": 20} -> True
        _ -> False
    assert a ==  True
