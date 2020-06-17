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

def convert((:lambda, meta, [args, statements])):
    args = args
        |> Elixir.Enum.map(&old_convert/1)
        |> Elixir.Enum.join(", ")

    Elixir.Enum.join([
        "{:fn, ", convert_meta(meta), ", [{:->, ", convert_meta(meta), ", [[",
        args,
        "], ",
        old_convert(statements),
        "]}]}"
    ])

def convert((:def, meta, [name, args, statements])):
    args = Elixir.Enum.map(args, &old_convert/1) |> Elixir.Enum.join(', ')

    Elixir.Enum.join([
        "{:def, ", convert_meta(meta), ", [{:", name, ", ", convert_meta(meta),", [",
        args, "]}, [do: ", old_convert(statements), "]]}"
    ])

def convert((:static_access, meta, [node_to_access, node_key])):
        Elixir.Enum.join([
        "{{:., ", convert_meta(meta), ", [{:__aliases__, [alias: false], [:Map]}, :fetch!]}, ", convert_meta(meta), ", [",
        old_convert(node_to_access), ", ", old_convert(node_key), "]}"
    ])

def convert((:raise, meta, [expr])):
    Elixir.Enum.join(["{:raise, ", convert_meta(meta), ", [", old_convert(expr), "]}"])

def get_childs({"_new": (:pipe, _, [left_node, right_node])}):
    [get_childs(left_node), get_childs(right_node)]

def get_childs(right_or_left_node):
    [right_or_left_node]

def convert((:pipe, meta, [left_node, right_node])):
    # Actually, we never convert to elixir pipe ast
    # Instead, we do elixir job to put the left node of the pipe
    # as the first parameter of the right node
    # We do this because elixir pipe ast doesnt work well
    # with a erlang call in the right. Eg: "oii" |> :string.replace("o", "i")

    ([first], flat_pipe) = left_node
        |> get_childs()
        |> Elixir.List.insert_at(-1, get_childs(right_node))
        |> Elixir.List.flatten()
        |> Elixir.Enum.split(1)

    flat_pipe
        |> Elixir.Enum.reduce(
            first,
            lambda c_node, acc:
                (:call, meta, [node_to_call, args, keywords, local_call]) = c_node['_new']

                c_node
                    |> Elixir.Map.put(
                        "_new",
                        (:call, meta, [node_to_call, Elixir.List.insert_at(args, 0, acc), keywords, local_call])
                    )
        )
        |> old_convert()


def convert((:map, meta, pairs)):
    pairs = pairs
        |> Elixir.Enum.map(lambda (key, value):
            Elixir.Enum.join(["{", old_convert(key), ", ", old_convert(value), "}"])
        )
        |> Elixir.Enum.join(', ')

    Elixir.Enum.join(["{:%{}, ", convert_meta(meta), ", [", pairs, "]}"])

def convert((:case, meta, [expr, pairs])):

    pairs = pairs
        |> Elixir.Enum.map(lambda (left, right):
            Elixir.Enum.join([
                "{:->, ", convert_meta(meta), ", [[", old_convert(left), "], ", old_convert(right), "]}"
            ], '')
        )
        |> Elixir.Enum.join(', ')

    case expr:
        None -> Elixir.Enum.join([
                "{:cond, ", convert_meta(meta), ", [[do: [", pairs, "]]]}"
            ])
        _ -> Elixir.Enum.join([
                "{:case, ", convert_meta(meta), ", [", old_convert(expr), ", [do: [", pairs, "]]]}"
            ])

def convert_call_args(args, keywords):
    args = Elixir.Enum.map(args, &old_convert/1)

    keywords = keywords
        |> Elixir.Enum.map(lambda (key, value):
            Elixir.Enum.join(["[", key, ": ", old_convert(value), "]"])
        )

    Elixir.Enum.join([
        "[",
        [args, keywords] |> Elixir.List.flatten() |> Elixir.Enum.join(", "),
        "]"
    ])

def convert((:call, meta, [node_to_call, args, keywords, True])):
    arguments = convert_call_args(args, keywords)

    Elixir.Enum.join([
        "{{:., ", convert_meta(meta), ", [", old_convert(node_to_call), "]}, ",
        convert_meta(meta), ", ", arguments, "}"
    ])

def convert(full <- (:call, meta, [{"_new": (:var, _, [_, func_name])}, args, keywords, False])):
    # node_to_call will always be a VarAccessNode on a module call. E.g: Elixir.Map.get

    arguments = convert_call_args(args, keywords)

    case Elixir.String.contains?(func_name, '.'):
        True ->
            (function, modules) = func_name
                |> Elixir.String.split(".")
                |> Elixir.List.pop_at(-1)

            # for fython modules we need to use the elixir
            # syntax for erlang calls. Doing this way, we prevent
            # Elixer compiler from adding 'Elixir.' to module name to call

            module = Elixir.Enum.join(modules, ".")

            module = case:
                Elixir.String.starts_with?(module, "Elixir.") -> module
                Elixir.String.starts_with?(module, "Erlang.") ->
                    Elixir.Enum.join([':"', Elixir.String.replace(module, "Erlang.", ""), '"'])
                True -> Elixir.Enum.join([':"Fython.', module, '"'])

            Elixir.Enum.join([
                "{{:., ", convert_meta(meta), ", [", module, ", :",
                function, "]}, ", convert_meta(meta), ", ", arguments, "}"
            ])
        False ->
            # this is for call a function that is defined in
            # the same module
            Elixir.Enum.join(["{:", func_name, ", ", convert_meta(meta), ", ", arguments, "}"])

def convert((:try, meta, [try_block, exceptions, finally_block])):
    do = Elixir.Enum.join([
        "{:do, ", old_convert(try_block), "}"
    ])

    each_rescue = Elixir.Enum.map(
        exceptions,
        lambda i :
            (except_identifier, alias, block) = i

            case alias:
                None -> Elixir.Enum.join([
                    "{:->, ", convert_meta(meta), ", [[{:__aliases__, [alias: false], [:",
                    except_identifier, "]}], ", old_convert(block), "]}"
                ])
                _ -> Elixir.Enum.join([
                    "{:->, ", convert_meta(meta), ",", "[[",
                    "{:in, ", convert_meta(meta), ",",
                    "[{:", alias, ", ", convert_meta(meta), ", Elixir}, {:__aliases__, [alias: false], [:", except_identifier, "]}]}",
                    "],", old_convert(block), "]}"
                ])
    )

    each_rescue = Elixir.Enum.join(each_rescue, ", ")

    rescue = Elixir.Enum.join([
        "{:rescue, [", each_rescue, "]}"
    ])

    Elixir.Enum.join([
        "{:try, ", convert_meta(meta), ", [[", do, ", ", rescue, "]]}"
    ])