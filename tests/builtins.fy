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

def test_list():
    assert list([]) == []
    assert list([1, 2]) == [1, 2]

    assert list(('a', 'b')) == ['a', 'b']
    assert list({"a": None, "b": None}) == ['a', 'b']
    assert list(10..13) == [10, 11, 12, 13]

def test_tuple():
    assert tuple(()) == ()
    assert tuple((1, 2)) == (1, 2)

    assert tuple(['a', 'b']) == ('a', 'b')
    assert tuple({"a": None, "b": None}) == ('a', 'b')
    assert tuple(10..13) == (10, 11, 12, 13)

def test_atom():
    assert atom(:my_atom) == :my_atom
    assert atom("a") == :a
    assert atom("Fython.Module") == :"Fython.Module"

def test_int():
    assert int(False) == 0
    assert int(True) == 1
    assert int(1) == 1
    assert int(1.0) == 1
    assert int('10') == 10

    assert Elixir.Kernel.is_integer(int(False))
    assert Elixir.Kernel.is_integer(int(True))
    assert Elixir.Kernel.is_integer(int(1))
    assert Elixir.Kernel.is_integer(int(1.0))
    assert Elixir.Kernel.is_integer(int('10'))

def test_float():
    assert float(False) == 0.0
    assert float(True) == 1.0
    assert float(1.0) == 1.0
    assert float(1) == 1.0
    assert float('10') == 10.0

    assert Elixir.Kernel.is_float(float(False))
    assert Elixir.Kernel.is_float(float(True))
    assert Elixir.Kernel.is_float(float(1.0))
    assert Elixir.Kernel.is_float(float(1))
    assert Elixir.Kernel.is_float(float('10'))

def test_map():
    assert map([0, 1, 2], lambda i: i + 10) == [10, 11, 12]
    assert map(10..12, lambda i: i + 10) == [20, 21, 22]
