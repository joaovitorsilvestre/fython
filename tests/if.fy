def test_if():
    a = 1 if True else 0
    assert a == 1

    a = "a" if False else "b"
    assert a == "b"