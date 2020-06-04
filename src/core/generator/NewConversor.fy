def convert_meta(_):
    # TODO
    '[]'

def old_convert(node):
    Core.Generator.Conversor.convert(node)

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

def convert((:string, meta, [value])):
    Elixir.Enum.join(['{:<<>>, ', convert_meta(meta), ', ["', value, '"]}'])

def convert((:unary, meta, [:minus, node])):
    Elixir.Enum.join([
        "{:-, ", convert_meta(meta), ", [", old_convert(node), "]}"
    ])

def convert((:unary, meta, [:plus, node])):
    Elixir.Enum.join([
        "{:+, ", convert_meta(meta), ", [", old_convert(node), "]}"
    ])

def convert((:unary, meta, [:not, node])):
    Elixir.Enum.join([
        "{:__block__, ", convert_meta(meta), ", [{:!, ", convert_meta(meta), ", [", old_convert(node), "]}]}"
    ])

def convert((:list, meta, elements)):
    Elixir.Enum.join([
        "[",
        Elixir.Enum.join(Elixir.Enum.map(elements, &old_convert/1), ", "),
        "]"
    ])

def convert((:tuple, meta, elements)):
    Elixir.Enum.join([
        "{:{}, ",
        convert_meta(meta),
        ", [",
        Elixir.Enum.join(Elixir.Enum.map(elements, &old_convert/1), ", "),
        "]}"
    ])
