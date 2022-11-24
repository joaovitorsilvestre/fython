def test_pattern_matching():
    {"a": a} = {"a": 2}
    assert a == 2

    (a,) = (1,)
    assert a == 1

    [a] = [10]
    assert a == 10

    {"nested": {"ola": ([a], 10)}} = {"nested": {"ola": ([50], 10)}}
    assert a == 50

def test_match_with_pin_variable():
    a = 10
    (^a, b) = (10, 30)
    assert a == 10
    assert b == 30