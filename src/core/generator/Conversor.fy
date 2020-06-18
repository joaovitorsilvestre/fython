def convert_meta(_):
    # TODO
    []

def convert(node):
    case Elixir.Kernel.elem(node, 0):
        :number         -> convert_number(node)
        :atom           -> convert_atom(node)
        :var            -> convert_var(node)
        :string         -> convert_string(node)
        :unary          -> convert_unary(node)
        :list           -> convert_list(node)
        :tuple          -> convert_tuple(node)
        :binop          -> convert_binop(node)
        :pattern        -> convert_pattern(node)
        :if             -> convert_if(node)
        :func           -> convert_func(node)
        :statements     -> convert_statements(node)
        :lambda         -> convert_lambda(node)
        :def            -> convert_def(node)
        :static_access  -> convert_static_access(node)
        :raise          -> convert_raise(node)
        :pipe           -> convert_pipe(node)
        :map            -> convert_map(node)
        :case           -> convert_case(node)
        :call           -> convert_call(node)
        :try            -> convert_try(node)

def convert_number((:number, _, [value])):
    value

def convert_atom((:atom, _, [value])):
    Elixir.String.to_atom(value)

def convert_var((:var, _, [_pinned, "True"])):
    True

def convert_var((:var, _, [_pinned, "False"])):
    False

def convert_var((:var, _, [_pinned, "None"])):
    None

def convert_var((:var, meta, [True, value])):
    # Elixir.Enum.join(["{:^, ", convert_meta(meta), ", [{:", value, ", ", convert_meta(meta), ", Elixir}]}"])
    (:"^", convert_meta(meta), [(Elixir.String.to_atom(value), convert_meta(meta), :Elixir)])

def convert_var((:var, meta, [False, value])):
    # Elixir.Enum.join(["{:", value, ",", convert_meta(meta), ", Elixir}"])

    (Elixir.String.to_atom(value), convert_meta(meta), :Elixir)

def convert_string((:string, meta, [value])):
    # Elixir.Enum.join(['{:<<>>, ', convert_meta(meta), ', ["', value, '"]}'])

    (:"<<>>", convert_meta(meta), [value])

def convert_unary((:unary, meta, [:minus, node])):
    #Elixir.Enum.join([
    #    "{:-, ", convert_meta(meta), ", [", convert(node), "]}"
    #])

    (:"-", convert_meta(meta), [convert(node)])

def convert_unary((:unary, meta, [:plus, node])):
    #Elixir.Enum.join([
    #    "{:+, ", convert_meta(meta), ", [", convert(node), "]}"
    #])
    (:"+", convert_meta(meta), [convert(node)])

def convert_unary((:unary, meta, [:not, node])):
    #Elixir.Enum.join([
    #    "{:__block__, ", convert_meta(meta), ", [{:!, ", convert_meta(meta), ", [", convert(node), "]}]}"
    #])

    (:"__block__", convert_meta(meta), [(:"!", convert_meta(meta), [convert(node)])])

def convert_list((:list, meta, elements)):
    #Elixir.Enum.join([
    #    "[",
    #    Elixir.Enum.join(Elixir.Enum.map(elements, &convert/1), ", "),
    #    "]"
    #])

    Elixir.Enum.map(elements, &convert/1)

def convert_tuple((:tuple, meta, elements)):
    #Elixir.Enum.join([
    #    "{:{}, ",
    #    convert_meta(meta),
    #    ", [",
    #    Elixir.Enum.join(Elixir.Enum.map(elements, &convert/1), ", "),
    #    "]}"
    #])

    (:"{}", convert_meta(meta), [Elixir.Enum.map(elements, &convert/1)])

def convert_binop((:binop, meta, [left, :or, right])):
    #Elixir.Enum.join([
    #    "{:or, ", convert_meta(meta), ", [", convert(left), ", ", convert(right), "]}"
    #])

    (:or, convert_meta(meta), [convert(left), convert(right)])

def convert_binop((:binop, meta, [left, :and, right])):
    #Elixir.Enum.join([
    #    "{:and, ", convert_meta(meta), ", [", convert(left), ", ", convert(right), "]}"
    #])
    (:and, convert_meta(meta), [convert(left), convert(right)])

def convert_binop((:binop, meta, [left, :in, right])):
    #Elixir.Enum.join([
    #    "{:in, ", convert_meta(meta), ", [", convert(left), ", ", convert(right), "]}"
    #])
    (:in, convert_meta(meta), [convert(left), convert(right)])

def convert_binop((:binop, meta, [left, :pow, right])):
    #Elixir.Enum.join([
    #    "{{:., ", convert_meta(meta), ", [:math, :pow]}, ", convert_meta(meta), ", [", convert(left), ", ", convert(right), "]}"
    #])

    ((:".", convert_meta(meta), [:math, :pow]), convert_meta(meta), [convert(left), convert(right)])

def convert_binop((:binop, meta, [left, op, right])):
    elixir_op = {
        :plus: '+', :minus: '-', :mul: '*', :div: '/',
        :gt: '>', :gte: '>=', :lt: '<', :lte: '<=',
        :ee: '==', :ne: '!=', :in: 'in'
    }

    #Elixir.Enum.join([
    #    "{:", elixir_op[op], ", ", convert_meta(meta), ", [", convert(left), ", ", convert(right), "]}"
    #])

    (Elixir.String.to_atom(elixir_op[op]), convert_meta(meta), [convert(left), convert(right)])

def convert_pattern((:pattern, meta, [left, right])):
    #Elixir.Enum.join([
    #    "{:=, ",
    #    convert_meta(meta), ", ",
    #    "[", convert(left) , ", ", convert(right) , "]",
    #    "}"
    #])

    (:"=", convert_meta(meta), [convert(left), convert(right)])

def convert_if((:if, meta, [comp_expr, true_case, false_case])):
    #Elixir.Enum.join([
    #    "{:if, ", convert_meta(meta), ", [",
    #    convert(comp_expr),
    #    ", [do: ",
    #    convert(true_case),
    #    ", else: ",
    #    convert(false_case),
    #    "]]}"
    #])

    (:if, convert_meta(meta), [convert(comp_expr), [(:do, convert(true_case)), (:else, convert(false_case))]])

def convert_func((:func, meta, [name, arity])):
    #Elixir.Enum.join([
    #    "{:&, ", convert_meta(meta), ", [{:/, ", convert_meta(meta), ", [{:",
    #    name, ", ", convert_meta(meta), ", Elixir}, ", arity, "]}]}"
    #])

    (
        :"&",
        convert_meta(meta),
        [(:"/", convert_meta(meta), [(Elixir.String.to_atom(name), convert_meta(meta), :Elixir), arity])]
    )

def convert_statements((:statements, meta, nodes)):
    content = Elixir.Enum.map(nodes, &convert/1)

    case Elixir.Enum.count(content):
        1 -> Elixir.Enum.at(content, 0)
        _ ->
            #Elixir.Enum.join([
            #    '{:__block__, ', convert_meta(meta), ', [', Elixir.Enum.join(content, ', '), ']}'
            #])
            (:"__block__", convert_meta(meta), content)

def convert_lambda((:lambda, meta, [args, statements])):
    args = args
        |> Elixir.Enum.map(&convert/1)
        # |> Elixir.Enum.join(", ")

    #Elixir.Enum.join([
    #    "{:fn, ", convert_meta(meta), ", [{:->, ", convert_meta(meta), ", [[",
    #    args,
    #    "], ",
    #    convert(statements),
    #    "]}]}"
    #])

    (:fn, convert_meta(meta), [(:"->", convert_meta(meta), [args, convert(statements)])])

def convert_def((:def, meta, [name, args, statements])):
    args = Elixir.Enum.map(args, &convert/1) # |> Elixir.Enum.join(', ')

    #Elixir.Enum.join([
    #    "{:def, ", convert_meta(meta), ", [{:", name, ", ", convert_meta(meta),", [",
    #    args, "]}, [do: ", convert(statements), "]]}"
    #])

    (
        :def,
        convert_meta(meta),
        [
            (Elixir.String.to_atom(name), convert_meta(meta), args),
            [(:do, convert(statements))]
        ]
    )

def convert_static_access((:static_access, meta, [node_to_access, node_key])):
    #Elixir.Enum.join([
    #    "{{:., ", convert_meta(meta), ", [{:__aliases__, [alias: false], [:Map]}, :fetch!]}, ", convert_meta(meta), ", [",
    #    convert(node_to_access), ", ", convert(node_key), "]}"
    #])

    (
        (:".", convert_meta(meta), [(:"__aliases__", [(:alias, False)], [:Map]), :fetch!]),
        convert_meta(meta),
        [convert(node_to_access), convert(node_key)]
    )

def convert_raise((:raise, meta, [expr])):
    # Elixir.Enum.join(["{:raise, ", convert_meta(meta), ", [", convert(expr), "]}"])
    (:raise, convert_meta(meta), [convert(expr)])

def get_childs((:pipe, _, [left_node, right_node])):
    [get_childs(left_node), get_childs(right_node)]

def get_childs(right_or_left_node):
    [right_or_left_node]

def convert_pipe((:pipe, meta, [left_node, right_node])):
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
                (:call, meta, [node_to_call, args, keywords, local_call]) = c_node

                (:call, meta, [node_to_call, Elixir.List.insert_at(args, 0, acc), keywords, local_call])
        )
        |> convert()


def convert_map((:map, meta, pairs)):
    pairs = pairs
        |> Elixir.Enum.map(lambda (key, value):
            # Elixir.Enum.join(["{", convert(key), ", ", convert(value), "}"])
            (convert(key), convert(value))
        )
        #|> Elixir.Enum.join(', ')

    # Elixir.Enum.join(["{:%{}, ", convert_meta(meta), ", [", pairs, "]}"])
    (:'%{}', convert_meta(meta), pairs)

def convert_case((:case, meta, [expr, pairs])):

    pairs = pairs
        |> Elixir.Enum.map(lambda (left, right):
            #Elixir.Enum.join([
            #    "{:->, ", convert_meta(meta), ", [[", convert(left), "], ", convert(right), "]}"
            #], '')
            (:"->", convert_meta(meta), [[convert(left)], convert(right)])
        )
        #|> Elixir.Enum.join(', ')

    case expr:
        None ->
            #Elixir.Enum.join([
            #    "{:cond, ", convert_meta(meta), ", [[do: [", pairs, "]]]}"
            #])
            (:cond, convert_meta(meta), [[(:do, pairs)]])
        _ ->
            #Elixir.Enum.join([
            #    "{:case, ", convert_meta(meta), ", [", convert(expr), ", [do: [", pairs, "]]]}"
            #])
            (:case, convert_meta(meta), [convert(expr), [(:do, pairs)]])


def convert_call_args(args, keywords):
    args = Elixir.Enum.map(args, &convert/1)

    keywords = keywords
        |> Elixir.Enum.map(lambda (key, value):
            #Elixir.Enum.join(["[", key, ": ", convert(value), "]"])
            [(:key, convert(value))]
        )

    #Elixir.Enum.join([
    #    "[",
    #    [args, keywords] |> Elixir.List.flatten() |> Elixir.Enum.join(", "),
    #    "]"
    #])
    Elixir.List.flatten([args, keywords])


def convert_call((:call, meta, [node_to_call, args, keywords, True])):
    arguments = convert_call_args(args, keywords)

    #Elixir.Enum.join([
    #    "{{:., ", convert_meta(meta), ", [", convert(node_to_call), "]}, ",
    #    convert_meta(meta), ", ", arguments, "}"
    #])
    (
        (:".", convert_meta(meta), [convert(node_to_call)]),
        convert_meta(meta),
        arguments
    )

def convert_call(full <- (:call, meta, [(:var, _, [_, func_name]), args, keywords, False])):
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
                    #Elixir.Enum.join([':"', Elixir.String.replace(module, "Erlang.", ""), '"'])
                    Elixir.String.replace(module, "Erlang.", "")
                True ->
                    #Elixir.Enum.join([':"Fython.', module, '"'])
                    Elixir.Enum.join(['Fython.', module])

            module = Elixir.String.to_atom(module)

            #Elixir.Enum.join([
            #    "{{:., ", convert_meta(meta), ", [", module, ", :",
            #    function, "]}, ", convert_meta(meta), ", ", arguments, "}"
            #])
            (
                (:".", convert_meta(meta), [module, Elixir.String.to_atom(function)]),
                convert_meta(meta),
                arguments
            )
        False ->
            # this is for call a function that is defined in
            # the same module
            # Elixir.Enum.join(["{:", func_name, ", ", convert_meta(meta), ", ", arguments, "}"])
            (Elixir.String.to_atom(func_name), convert_meta(meta), arguments)

def convert_try((:try, meta, [try_block, exceptions, finally_block])):
    #do = Elixir.Enum.join([
    #    "{:do, ", convert(try_block), "}"
    #])
    do = (:do, convert(try_block))

    each_rescue = Elixir.Enum.map(
        exceptions,
        lambda i :
            (except_identifier, alias, block) = i

            case alias:
                None ->
                    #Elixir.Enum.join([
                    #    "{:->, ", convert_meta(meta), ", [[{:__aliases__, [alias: false], [:",
                    #    except_identifier, "]}], ", convert(block), "]}"
                    #])
                    (
                        :"->",
                        convert_meta(meta),
                        [
                            [(:'__aliases__', [(:alias, False)], [Elixir.String.to_atom(except_identifier)])],
                            convert(block)
                        ]
                    )
                _ ->
                    #Elixir.Enum.join([
                    #    "{:->, ", convert_meta(meta), ",", "[[",
                    #    "{:in, ", convert_meta(meta), ",",
                    #    "[{:", alias, ", ", convert_meta(meta), ", Elixir}, {:__aliases__, [alias: false], [:", except_identifier, "]}]}",
                    #    "],", convert(block), "]}"
                    #])
                    (
                        :"->",
                        convert_meta(meta),
                        [[
                            (
                                :in,
                                convert_meta(meta),
                                :Elixir
                            ),
                            (
                                :'__aliases__',
                                [(:alias, False)],
                                [Elixir.String.to_atom(except_identifier)]
                            )
                        ]]
                    )
    )

    #each_rescue = Elixir.Enum.join(each_rescue, ", ")

    #rescue = Elixir.Enum.join([
    #    "{:rescue, [", each_rescue, "]}"
    #])
    rescue = (:rescue, each_rescue)

    #Elixir.Enum.join([
    #    "{:try, ", convert_meta(meta), ", [[", do, ", ", rescue, "]]}"
    #])
    (:try, convert_meta(meta), [[do, rescue]])