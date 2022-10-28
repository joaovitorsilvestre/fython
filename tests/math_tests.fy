def run_tests():
    test_numbers()
    test_basic_operations()
    test_strings()
    test_dicts()
    test_lists()
    test_lambda()
    test_tuples()
    test_pattern_matching()
    test_pipe_operator()
    test_case()

def test_numbers():
    assert_equal(1_000, 1000)
    assert_equal(1_000_000, 1000000)
    assert_equal(1_000.5, 1000 + 0.5)

def test_basic_operations():
    assert_equal(1 / 2, 0.5)
    assert_equal(1 + 2 - 3, 0)
    assert_equal(1 - 2 - 3, -4)
    assert_equal(1 + 2, 3)
    assert_equal(90 / 2, 45)
    assert_equal(90 / 2 + 10, 55)
    assert_equal(10 + 10 / 10, 11)
    assert_equal((10 + 10) / 10, 2)
    assert_equal(10 * 10 / 20, 5)
    assert_equal(10 * (10 / 20), 5)
    assert_equal(3 ** 2, 9)
    assert_equal(3 ** 3, 27)
    assert_equal(3 ** 3 * 2, 54)

def test_strings():
    assert_equal('a', "a")

def test_lists():
    a = [1, 2, 3]
    assert_equal(Elixir.Enum.at(a, 0), 1)
    assert_equal(Elixir.Enum.at(a, 1), 2)
    assert_equal(Elixir.Enum.at(a, 2), 3)

def test_dicts():
    a = {'a': 2}
    assert_equal(a['a'], 2)

    a = Elixir.Map.put(a, 'b', 20)
    assert_equal(a['b'], 20)
    assert_equal(a, {"a": 2, 'b': 20})

    key = 50
    a = {key: "a"}
    assert_equal(a[50], "a")

def test_lambda():
    a = lambda a, b: a + b
    assert_equal(a(10, 15), 25)

    assert_equal(Elixir.Enum.map([1, 2, 3], lambda x: x + 1), [2, 3, 4])

def test_tuples():
    assert_equal((10,) |> Elixir.Kernel.elem(0), 10)
    assert_equal((1, 2) |> Elixir.Kernel.elem(0), 1)
    assert_equal((1, 2) |> Elixir.Kernel.elem(1), 2)

def test_pattern_matching():
    {"a": a} = {"a": 2}
    assert_equal(a, 2)

    (a,) = (1,)
    assert_equal(a, 1)

    [a] = [10]
    assert_equal(a, 10)

    {"nested": {"ola": ([a], 10)}} = {"nested": {"ola": ([50], 10)}}
    assert_equal(a, 50)

def test_pipe_operator():
    [1, 2, 3] |> Elixir.Enum.map(lambda x: x * -1) |> assert_equal([-1, -2, -3])

def test_range():
    assert_equal(Elixir.Enum.to_list(1..5), [1, 2, 3, 4, 5])
    assert_equal(Elixir.Enum.to_list(5..0), [5, 4, 3, 2, 1])

def test_case():
    a = case True:
        True -> "s"
        False -> "n"
    assert_equal(a, "s")

    a = case {"a": 20}:
        {"a": 10} -> True
        _ -> False
    assert_equal(a, False)

    a = case {"a": 20}:
        {"a": 20} -> True
        _ -> False
    assert_equal(a, True)

def assert_equal(a, b):
    case a == b:
        False -> raise "It's not equal"
        True -> None