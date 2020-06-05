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
    Elixir.Enum.join(["{:^, ", convert_meta(meta), ", [{:", value, ", ", convert_meta(meta), ", Elixir}]}"])

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

def convert((:binop, meta, [left, :or, right])):
    Elixir.Enum.join([
        "{:or, ", convert_meta(meta), ", [", old_convert(left), ", ", old_convert(right), "]}"
    ])

def convert((:binop, meta, [left, :and, right])):
    Elixir.Enum.join([
        "{:and, ", convert_meta(meta), ", [", old_convert(left), ", ", old_convert(right), "]}"
    ])

def convert((:binop, meta, [left, :in, right])):
    Elixir.Enum.join([
        "{:in, ", convert_meta(meta), ", [", old_convert(left), ", ", old_convert(right), "]}"
    ])

def convert((:binop, meta, [left, :pow, right])):
    Elixir.Enum.join([
        "{{:., ", convert_meta(meta), ", [:math, :pow]}, ", convert_meta(meta), ", [", old_convert(left), ", ", old_convert(right), "]}"
    ])

def convert((:binop, meta, [left, op, right])):
    elixir_op = {
        :plus: '+', :minus: '-', :mul: '*', :div: '/',
        :gt: '>', :gte: '>=', :lt: '<', :lte: '<=',
        :ee: '==', :ne: '!=', :in: 'in'
    }

    Elixir.Enum.join([
        "{:", elixir_op[op], ", ", convert_meta(meta), ", [", old_convert(left), ", ", old_convert(right), "]}"
    ])

def convert((:pattern, meta, [left, right])):
    Elixir.Enum.join([
        "{:=, ",
        convert_meta(meta), ", ",
        "[", old_convert(left) , ", ", old_convert(right) , "]",
        "}"
    ])

def convert((:if, meta, [comp_expr, true_case, false_case])):
    Elixir.Enum.join([
        "{:if, ", convert_meta(meta), ", [",
        old_convert(comp_expr),
        ", [do: ",
        old_convert(true_case),
        ", else: ",
        old_convert(false_case),
        "]]}"
    ])

def convert((:func, meta, [name, arity])):
    Elixir.Enum.join([
        "{:&, ", convert_meta(meta), ", [{:/, ", convert_meta(meta), ", [{:",
        name, ", ", convert_meta(meta), ", Elixir}, ", arity, "]}]}"
    ])

def convert((:statements, meta, nodes)):
    content = Elixir.Enum.map(nodes, &old_convert/1)

    case Elixir.Enum.count(content):
        1 -> Elixir.Enum.at(content, 0)
        _ -> Elixir.Enum.join([
            '{:__block__, ', convert_meta(meta), ', [', Elixir.Enum.join(content, ', '), ']}'
        ])










