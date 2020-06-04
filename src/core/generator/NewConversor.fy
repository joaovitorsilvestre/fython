def convert_meta(_):
    # TODO
    '[]'

def convert((:number, _, [value])):
    Elixir.Kernel.to_string(value)

def convert((:atom, _, [value])):
    Elixir.Enum.join([":", value])

def convert((:var, _, [_pinned, "True"])):
    "true"

def convert((:var, _, [_pinned, "False"])):
    "false"

def convert((:var, _, [_pinned, "None"])):
    "nil"

def convert((:var, meta, [True, value])):
    i = convert((:var, meta, [False, value]))
    Elixir.Enum.join(["{:^, ", convert_meta(meta), ", [", i, "]}"])

def convert((:var, meta, [False, value])):
    Elixir.Enum.join(["{:", value, ",", convert_meta(meta), ", Elixir}"])
