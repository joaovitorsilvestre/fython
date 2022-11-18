def convert_meta((nodetype, {"ref_line": line}, body)):
    # We are compiling a module
    # Se we will use line numbers as keys, that we can later
    # get the full meta of the node.
    # We need this because elixir __STACKTRACE__ only inform us the line
    # and to give users better errors messages, we need
    # the position of tokens (eg. column in the curent line, etc)
    # that we have in original meta
    (nodetype, [(:line, line)], body)

def convert_meta((nodetype, {"start": (_coll, line, _index)}, body)):
    meta = [(:line, line + 1)]
    (nodetype, meta, body)

def convert(node):
    case Elixir.Kernel.elem(node, 0):
        :number         -> node |> convert_meta() |> convert_number()
        :atom           -> node |> convert_meta() |> convert_atom()
        :var            -> node |> convert_meta() |> convert_var()
        :string         -> node |> convert_meta() |> convert_string()
        :unary          -> node |> convert_meta() |> convert_unary()
        :list           -> node |> convert_meta() |> convert_list()
        :tuple          -> node |> convert_meta() |> convert_tuple()
        :binop          -> node |> convert_meta() |> convert_binop()
        :pattern        -> node |> convert_meta() |> convert_pattern()
        :if             -> node |> convert_meta() |> convert_if()
        :func           -> node |> convert_meta() |> convert_func()
        :statements     -> node |> convert_meta() |> convert_statements()
        :lambda         -> node |> convert_meta() |> convert_lambda()
        :def            -> node |> convert_meta() |> convert_def()
        :static_access  -> node |> convert_meta() |> convert_static_access()
        :raise          -> node |> convert_meta() |> convert_raise()
        :assert         -> node |> convert_meta() |> convert_assert()
        :pipe           -> node |> convert_meta() |> convert_pipe()
        :map            -> node |> convert_meta() |> convert_map()
        :case           -> node |> convert_meta() |> convert_case()
        :call           -> node |> convert_meta() |> convert_call()
        :try            -> node |> convert_meta() |> convert_try()
        :range          -> node |> convert_meta() |> convert_range_node()
        :struct_call    -> node |> convert_meta() |> convert_struct_call_node()

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
    (:"^", meta, [(Elixir.String.to_atom(value), meta, :Elixir)])

def convert_var((:var, meta, [False, value])):
    (Elixir.String.to_atom(value), meta, :Elixir)

def convert_string((:string, meta, [value])):
    value

def convert_unary((:unary, meta, [:minus, node])):
    (:"-", meta, [convert(node)])

def convert_unary((:unary, meta, [:plus, node])):
    (:"+", meta, [convert(node)])

def convert_unary((:unary, meta, [:not, node])):
    (:"__block__", meta, [(:"!", meta, [convert(node)])])

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
                        meta,
                        [(:__aliases__, [(:alias, False)], [Elixir.String.to_atom("Elixir.Enum")]), :concat]
                    ),
                    meta,
                    [acc, item]
                )
        )

def convert_list(node <- (:list, meta, elements)):
    case Elixir.Enum.find(elements, &is_unpack/1):
        None -> Elixir.Enum.map(elements, &convert/1)
        _ -> convert_list_with_unpack(node)

def convert_tuple((:tuple, meta, elements)):
    (:"{}", meta, Elixir.Enum.map(elements, &convert/1))

def convert_binop((:binop, meta, [left, :or, right])):
    (:or, meta, [convert(left), convert(right)])

def convert_binop((:binop, meta, [left, :and, right])):
    (:and, meta, [convert(left), convert(right)])

def convert_binop((:binop, meta, [left, :in, right])):
    (:in, meta, [convert(left), convert(right)])

def convert_binop((:binop, meta, [left, :pow, right])):
    ((:".", meta, [:math, :pow]), meta, [convert(left), convert(right)])

def convert_binop((:binop, meta, [left, op, right])):
    elixir_op = {
        :plus: '+', :minus: '-', :mul: '*', :div: '/',
        :gt: '>', :gte: '>=', :lt: '<', :lte: '<=',
        :ee: '==', :ne: '!=', :in: 'in'
    }

    (Elixir.String.to_atom(elixir_op[op]), meta, [convert(left), convert(right)])

def convert_pattern((:pattern, meta, [left, right])):
    (:"=", meta, [convert(left), convert(right)])

def convert_if((:if, meta, [comp_expr, true_case, false_case])):
    (:if, meta, [convert(comp_expr), [(:do, convert(true_case)), (:else, convert(false_case))]])

def convert_func((:func, meta, [name, arity])):
    (
        :"&",
        meta,
        [(:"/", meta, [(Elixir.String.to_atom(name), meta, :Elixir), arity])]
    )

def convert_statements((:statements, meta, nodes)):
    content = Elixir.Enum.map(nodes, &convert/1)

    case Elixir.Enum.count(content):
        1 -> Elixir.Enum.at(content, 0)
        _ -> (:"__block__", meta, content)

def convert_lambda((:lambda, meta, [args, statements])):
    args = args |> Elixir.Enum.map(&convert/1)

    (:fn, meta, [(:"->", meta, [args, convert(statements)])])


def convert_def((:def, meta, [name, args, guards, statements])):
    args = Elixir.Enum.map(args, &convert/1)

    func_name_quoted = case guards:
        (:guard, guards_meta, [guard_expr]) ->
            # TODO seria bom que o guards já estivese convertido
            # TODO vamos poder fazer isso quando tivermos os guards haha (tendo uma função para tratar diferentes defs)
            (_, guards_meta, _) = convert_meta(guards)
            (
                :when,
                guards_meta,
                [
                    (Elixir.String.to_atom(name), meta, args),
                    convert(guard_expr)
                ]
            )
        [] -> (Elixir.String.to_atom(name), meta, args)

    (
        :def,
        meta,
        [
            func_name_quoted,
            [(:do, convert(statements))]
        ]
    )

def convert_static_access((:static_access, meta, [node_to_access, node_key])):
    (
        (:".", meta, [(:"__aliases__", [(:alias, False)], [:Map]), :fetch!]),
        meta,
        [convert(node_to_access), convert(node_key)]
    )

def convert_raise((:raise, meta, [expr])):
    (:raise, meta, [convert(expr)])

def convert_assert((:assert, meta, [expr])):
    # Doesnt exist assert in Elixir
    raise_error = (:raise, meta, ["Assertion error"])

    is_false = (:"==", meta, [convert(expr), False])
    is_none = (:"==", meta, [convert(expr), None])
    is_zero = (:"==", meta, [convert(expr), 0])

    (
        :cond,
        meta,
        [[
            (:do, [
                # TODO vamos ter que ter um protocolo para saber se algo o valor boleano
                # TODO por enquanto vai ser assim
                (:"->", meta, [[is_false], raise_error]),
                (:"->", meta, [[is_none], raise_error]),
                (:"->", meta, [[is_zero], raise_error]),
                (:"->", meta, [[True], None])
            ])
        ]]
    )

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
                        meta,
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
                        meta,
                        [(:__aliases__, [(:alias, False)], [Elixir.String.to_atom("Elixir.Map")]), :merge]
                    ),
                    meta,
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

            (:'%{}', meta, pairs)
        _ -> convert_map_with_spread(node)

def convert_case((:case, meta, [expr, pairs])):

    pairs = pairs
        |> Elixir.Enum.map(lambda (left, right):
            (:"->", meta, [[convert(left)], convert(right)])
        )

    case expr:
        None -> (:cond, meta, [[(:do, pairs)]])
        _ -> (:case, meta, [convert(expr), [(:do, pairs)]])


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
        (:".", meta, [convert(node_to_call)]),
        meta,
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
                (:".", meta, [module, Elixir.String.to_atom(function)]),
                meta,
                arguments
            )
        False ->
            # this is for call a function that is defined in
            # the same module
            (Elixir.String.to_atom(func_name), meta, arguments)

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
                        meta,
                        [
                            [(Elixir.String.to_atom(except_identifier), meta, :Elixir)],
                            convert(block)
                        ]
                    )
                (True, _) ->
                    # Case of:
                    # > except ArithmeticError as error:
                    (
                        :"->",
                        meta,
                        [
                            [
                                (
                                    :in,
                                    meta,
                                    [
                                        (Elixir.String.to_atom(alias), meta, :Elixir),
                                        (:'__aliases__', [(:alias, False)], [Elixir.String.to_atom(except_identifier)])
                                    ]
                                )
                            ],
                            convert(block)
                        ]
                    )
    )

    rescue = (:rescue, each_rescue)

    (:try, meta, [[do, rescue]])

def convert_range_node((:range, meta, [left_node, right_node])):
    (
        (
            :".",
            meta,
            [(:__aliases__, [(:alias, False)], [Elixir.String.to_atom("Elixir.Range")]), :new]
        ),
        meta,
        [convert(left_node), convert(right_node)]
    )

def convert_struct_node(
    node <- (:statements, _, body)
):
    # Structs will be converted to a Elixir module
    # So we need to return the struct name because it will be the module's name
    ([struct], other_statements) = Elixir.Enum.split_with(
        body, lambda (node_type, _, _): node_type == :struct
    )
    (:struct, meta, [struct_name, _, _]) = struct
    struct_statements = convert_struct_node(struct)

    # these are the helper functions that we inject
    other_statements = Elixir.Enum.map(other_statements, &convert/1)

    (:statements, meta, _) = convert_meta(node)

    (struct_name, (:"__block__", meta, [*struct_statements, *other_statements]))


def convert_struct_node(
    node <- (:struct, _, _)
):
    (:struct, meta, [struct_name, struct_fields, functions_struct]) = convert_meta(node)

    functions_struct = Elixir.Enum.map(functions_struct, &convert/1)

    [
        (
            :defstruct,
            meta,
            [Elixir.Enum.map(
                struct_fields,
                lambda (n, d):
                    (Elixir.String.to_atom(n), convert(d))
            )]
        ),
        *functions_struct
    ]

def convert_struct_call_node((:struct_call, meta, [struct_name, keywords])):
    struct_name = Elixir.String.to_atom(Elixir.Enum.join(["Fython", ".", struct_name]))

    keywords_converted = Elixir.Enum.map(keywords, lambda (key, value):
        (Elixir.String.to_atom(key), convert(value))
    )

    (
        (:".", meta, [struct_name, :__struct__]),
        meta,
        [(:"%{}", [], keywords_converted)]
    )
