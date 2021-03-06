def convert_meta({"start": (_coll, line, _index), "file": file}):
    [(:line, line + 1), (:file, file)]

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
        :range          -> convert_range_node(node)

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
    (:"^", convert_meta(meta), [(Elixir.String.to_atom(value), convert_meta(meta), :Elixir)])

def convert_var((:var, meta, [False, value])):
    (Elixir.String.to_atom(value), convert_meta(meta), :Elixir)

def convert_string((:string, meta, [value])):
    value = Elixir.Enum.join(['"', value,'"']) |> Elixir.Code.eval_string() |> Elixir.Kernel.elem(0)
    (:"<<>>", convert_meta(meta), [value])

def convert_unary((:unary, meta, [:minus, node])):
    (:"-", convert_meta(meta), [convert(node)])

def convert_unary((:unary, meta, [:plus, node])):
    (:"+", convert_meta(meta), [convert(node)])

def convert_unary((:unary, meta, [:not, node])):
    (:"__block__", convert_meta(meta), [(:"!", convert_meta(meta), [convert(node)])])

def is_unpack((:unpack, _, _)):
    True

def is_unpack(item):
    False

def convert_list_with_unpack((:list, meta, elements)):
    elements
        # after this step we will have all keys in senquence grouped
        # this step will avoid creating a Enum.concat command for each key that is not unpack
        |> Elixir.Enum.reduce(
            [],
            lambda item, acc:
                case [is_unpack(item), acc]:
                    [True, _] -> [*acc, item]
                    [False, []] -> [[item]]
                    [False, acc] ->
                        case is_unpack(Elixir.Enum.at(acc, -1)):
                            True -> [*acc, [item]]
                            False ->
                                last_group = Elixir.Enum.at(acc, -1)
                                Elixir.List.replace_at(acc, -1, [*last_group, item])
        )
        |> Elixir.Enum.map(
            lambda elements_or_unpack:
                case elements_or_unpack:
                    (:unpack, meta, [node_to_unpack]) -> convert(node_to_unpack)
                    _ -> Elixir.Enum.map(elements_or_unpack, &convert/1)
        )
        |> Elixir.Enum.reduce(
            lambda item, acc:
                (
                    (
                        :".",
                        convert_meta(meta),
                        [(:__aliases__, [(:alias, False)], [Elixir.String.to_atom("Elixir.Enum")]), :concat]
                    ),
                    convert_meta(meta),
                    [acc, item]
                )
        )

def convert_list(node <- (:list, meta, elements)):
    case Elixir.Enum.find(elements, &is_unpack/1):
        None -> Elixir.Enum.map(elements, &convert/1)
        _ -> convert_list_with_unpack(node)

def convert_tuple((:tuple, meta, elements)):
    (:"{}", convert_meta(meta), Elixir.Enum.map(elements, &convert/1))

def convert_binop((:binop, meta, [left, :or, right])):
    (:or, convert_meta(meta), [convert(left), convert(right)])

def convert_binop((:binop, meta, [left, :and, right])):
    (:and, convert_meta(meta), [convert(left), convert(right)])

def convert_binop((:binop, meta, [left, :in, right])):
    (:in, convert_meta(meta), [convert(left), convert(right)])

def convert_binop((:binop, meta, [left, :pow, right])):
    ((:".", convert_meta(meta), [:math, :pow]), convert_meta(meta), [convert(left), convert(right)])

def convert_binop((:binop, meta, [left, op, right])):
    elixir_op = {
        :plus: '+', :minus: '-', :mul: '*', :div: '/',
        :gt: '>', :gte: '>=', :lt: '<', :lte: '<=',
        :ee: '==', :ne: '!=', :in: 'in'
    }

    (Elixir.String.to_atom(elixir_op[op]), convert_meta(meta), [convert(left), convert(right)])

def convert_pattern((:pattern, meta, [left, right])):
    (:"=", convert_meta(meta), [convert(left), convert(right)])

def convert_if((:if, meta, [comp_expr, true_case, false_case])):
    (:if, convert_meta(meta), [convert(comp_expr), [(:do, convert(true_case)), (:else, convert(false_case))]])

def convert_func((:func, meta, [name, arity])):
    (
        :"&",
        convert_meta(meta),
        [(:"/", convert_meta(meta), [(Elixir.String.to_atom(name), convert_meta(meta), :Elixir), arity])]
    )

def convert_statements((:statements, meta, nodes)):
    content = Elixir.Enum.map(nodes, &convert/1)

    case Elixir.Enum.count(content):
        1 -> Elixir.Enum.at(content, 0)
        _ -> (:"__block__", convert_meta(meta), content)

def convert_lambda((:lambda, meta, [args, statements])):
    args = args |> Elixir.Enum.map(&convert/1)

    (:fn, convert_meta(meta), [(:"->", convert_meta(meta), [args, convert(statements)])])

def convert_def((:def, meta, [name, args, statements])):
    args = Elixir.Enum.map(args, &convert/1)

    (
        :def,
        convert_meta(meta),
        [
            (Elixir.String.to_atom(name), convert_meta(meta), args),
            [(:do, convert(statements))]
        ]
    )

def convert_static_access((:static_access, meta, [node_to_access, node_key])):
    (
        (:".", convert_meta(meta), [(:"__aliases__", [(:alias, False)], [:Map]), :fetch!]),
        convert_meta(meta),
        [convert(node_to_access), convert(node_key)]
    )

def convert_raise((:raise, meta, [expr])):
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

                (:call, meta, [node_to_call, [acc, *args], keywords, local_call])
        )
        |> convert()

def is_spread((:spread, _, _)):
    True

def is_spread(item):
    False

def convert_map_with_spread((:map, meta, pairs)):
    pairs
        # after this step we will have all keys in senquence grouped
        # this step will avoid creating a Map.merge command for each key that is not spread
        |> Elixir.Enum.reduce(
            [],
            lambda item, acc:
                case [is_spread(item), acc]:
                    [True, _] -> [*acc, item]
                    [False, []] -> [[item]]
                    [False, acc] ->
                        case is_spread(Elixir.Enum.at(acc, -1)):
                            True -> [*acc, [item]]
                            False ->
                                last_group = Elixir.Enum.at(acc, -1)
                                Elixir.List.replace_at(acc, -1, [*last_group, item])
        )
        # convert each group in a elixir ast map
        |> Elixir.Enum.map(
            lambda pairs_or_spread:
                case pairs_or_spread:
                    (:spread, meta, [node_to_spread]) -> convert(node_to_spread)
                    _ -> (
                        :'%{}',
                        convert_meta(meta),
                        Elixir.Enum.map(
                            pairs_or_spread,
                            lambda (key, value): (convert(key), convert(value))
                        )
                    )
        )
        |> Elixir.Enum.reduce(
            lambda item, acc:
                (
                    (
                        :".",
                        convert_meta(meta),
                        [(:__aliases__, [(:alias, False)], [Elixir.String.to_atom("Elixir.Map")]), :merge]
                    ),
                    convert_meta(meta),
                    [acc, item]
                )
        )

def convert_map(node <- (:map, meta, pairs)):
    case Elixir.Enum.find(pairs, &is_spread/1):
        None ->
            pairs = pairs
                |> Elixir.Enum.map(lambda (key, value):
                    (convert(key), convert(value))
                )

            (:'%{}', convert_meta(meta), pairs)
        _ -> convert_map_with_spread(node)

def convert_case((:case, meta, [expr, pairs])):

    pairs = pairs
        |> Elixir.Enum.map(lambda (left, right):
            (:"->", convert_meta(meta), [[convert(left)], convert(right)])
        )

    case expr:
        None -> (:cond, convert_meta(meta), [[(:do, pairs)]])
        _ -> (:case, convert_meta(meta), [convert(expr), [(:do, pairs)]])


def convert_call_args(args, keywords):
    args = Elixir.Enum.map(args, &convert/1)

    keywords = keywords
        |> Elixir.Enum.map(lambda (key, value):
            [(:key, convert(value))]
        )

    Elixir.Enum.concat(args, keywords)


def convert_call((:call, meta, [node_to_call, args, keywords, True])):
    arguments = convert_call_args(args, keywords)

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
            # Elixir compiler from adding 'Elixir.' to module name to call

            module = Elixir.Enum.join(modules, ".")

            module = case:
                Elixir.String.starts_with?(module, "Elixir.") -> module
                Elixir.String.starts_with?(module, "Erlang.") ->
                    Elixir.String.replace(module, "Erlang.", "")
                True ->
                    Elixir.Enum.join(['Fython.', module])

            module = Elixir.String.to_atom(module)
            (
                (:".", convert_meta(meta), [module, Elixir.String.to_atom(function)]),
                convert_meta(meta),
                arguments
            )
        False ->
            # this is for call a function that is defined in
            # the same module
            (Elixir.String.to_atom(func_name), convert_meta(meta), arguments)

def convert_try((:try, meta, [try_block, exceptions, finally_block])):
    do = (:do, convert(try_block))

    each_rescue = Elixir.Enum.map(
        exceptions,
        lambda i :
            (except_identifier, alias, block) = i

            is_alias_to_exception = Elixir.Kernel.is_bitstring(except_identifier) and Elixir.String.at(except_identifier, 0) == Elixir.String.upcase(Elixir.String.at(except_identifier, 0))

            case (is_alias_to_exception, alias):
                (False, None) ->
                    # Case of:
                    # > except error:
                    (
                        :"->",
                        convert_meta(meta),
                        [
                            [(Elixir.String.to_atom(except_identifier), convert_meta(meta), :Elixir)],
                            convert(block)
                        ]
                    )
                (False, None) ->
                    # Case of:
                    # > except ArithmeticError:
                    (
                        :"->",
                        convert_meta(meta),
                        [
                            [(:'__aliases__', [(:alias, False)], [Elixir.String.to_atom(except_identifier)])],
                            convert(block)
                        ]
                    )
                (True, _) ->
                    # Case of:
                    # > except ArithmeticError as error:
                    (
                        :"->",
                        convert_meta(meta),
                        [
                            [
                                (
                                    :in,
                                    convert_meta(meta),
                                    [
                                        (Elixir.String.to_atom(alias), convert_meta(meta), :Elixir),
                                        (:'__aliases__', [(:alias, False)], [Elixir.String.to_atom(except_identifier)])
                                    ]
                                )
                            ],
                            convert(block)
                        ]
                    )
    )

    rescue = (:rescue, each_rescue)

    (:try, convert_meta(meta), [[do, rescue]])

def convert_range_node((:range, meta, [left_node, right_node])):
    (
        (
            :".",
            convert_meta(meta),
            [(:__aliases__, [(:alias, False)], [Elixir.String.to_atom("Elixir.Range")]), :new]
        ),
        convert_meta(meta),
        [convert(left_node), convert(right_node)]
    )
