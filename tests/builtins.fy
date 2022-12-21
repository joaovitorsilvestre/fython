def test_sum():
    assert sum(1, 2) == 3
    assert 1 + 2 == 3

    assert sum("a", "b") == "ab"
    assert 'a' + 'b' == "ab"

    assert sum([1], [2]) == [1, 2]
    assert [1] + [2] == [1, 2]

def test_enumerate():
    assert list(enumerate(["a", "b"])) == [(0, "a"), (1, "b")]
    assert list(enumerate({"a": None, "b": None})) == [(0, "a"), (1, "b")]
    assert list(enumerate(10..13)) == [(0, 10), (1, 11), (2, 12), (3, 13)]
