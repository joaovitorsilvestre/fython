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

def nodes_that_are_own_modules():
    [:struct_def, :exception]

def run_conversor(module_name, (:statements, meta, nodes), file_content, config):
    # Return modules produced by the statements
    # returns: [
    #    (:ModuleName, elixir_ast_of_module, ["Module.Dependency"])
    # ]
    # structs, protocols are their own modules and
    # they must be the first ones of the list
    # TODO create way to detect circular deps

    config = Elixir.Map.put(config, "bootstrap_prefix", Elixir.Map.get(config, "bootstrap_prefix"))

    (separated_modules, current_module) = nodes
        |> Elixir.Enum.split_with(
            lambda (node_type, _, _): Elixir.Enum.member?(nodes_that_are_own_modules(), node_type)
        )

    separated_modules = separated_modules
        |> Elixir.Enum.map(lambda x:
            deps = Module.find_dependencies_of_module(x)

            (module_name, module) = (:statements, meta, [x])
                |> inject_module_info_if_compiling_module(file_content, config)
                |> convert_module(module_name, config)

            (module_name, module, deps)
        )

    current_module = (:statements, meta, current_module)
    deps = Module.find_dependencies_of_module(current_module)

    current_module = current_module
        |> inject_module_info_if_compiling_module(file_content, config)
#        |> inject_aliases_of_modules_used_in_module(separated_modules)
        |> convert(config)

    [*separated_modules, (module_name, current_module, deps)]
        |> remove_global_import_of_elixir_kernel(config)
        |> inject_fython_core_as_dependency(config)

def remove_global_import_of_elixir_kernel(modules, config):
    # We remove all imports from Elixir.Kernel, to avoid conflict
    # with functions of Fython.Core
    # This way we ensure that user only calls Elixir.Kernel functions with 'Elixir.' prefix

    modules = modules
        |> Elixir.Enum.map(lambda (module_name, ast, deps):
            (:'__block__', meta, statements) = ast

            # Functions that we dont want to be auto loaded from Elixir.Kernel
            functions_to_ignore = [
                (:apply, 2),
                (:apply, 3),
            ]

            # ast of 'import Kernel, only: [...]'
            import_no_function_from_elixir_kernel = (
                :import,
                [(:context, :Elixir)],
                [(:'__aliases__', [(:alias, False)], [:Kernel]), [(:except, functions_to_ignore)]]
            )

            ast = (:'__block__', meta, [import_no_function_from_elixir_kernel, *statements])
            (module_name, ast, deps)
        )


def inject_fython_core_as_dependency(modules, config):
    # modules: [(module_name, ast, deps)]

    bootstrap_prefix = Elixir.Map.get(config, 'bootstrap_prefix')

    modules
        |> Elixir.Enum.map(lambda (module_name, ast, deps):
            core_module_name = case bootstrap_prefix:
                None -> "Fython.Core"
                _ -> Elixir.Enum.join(["Fython.", bootstrap_prefix, ".Core"])

            case module_name:
                ^core_module_name ->
                    # Core module should not depend on itself
                    (module_name, ast, deps)
                _ ->
                    # imports Fython.Core automatically and add
                    # it as a dependency
                    deps = [core_module_name, *deps]

                    import_stm = (:import, [(:context, :Elixir)], [Elixir.String.to_atom(core_module_name)])

                    (:'__block__', meta, statements) = ast
                    ast = (:'__block__', meta, [import_stm, *statements])

                    (module_name, ast, deps)
        )


def inject_module_info_if_compiling_module(node, file_content, config):
    compiling_module = Elixir.Map.get(config, "compiling_module", False)

    case compiling_module:
        True -> node |> Core.Parser.Pos.Nodesrefs.run(file_content)
        False -> node

def inject_aliases_of_modules_used_in_module((:statements, meta, nodes), separated_modules):
    # This makes possible to use modules defined in the same file
    # (like exception, struct, protocol, etc) without need of the full name. Eg:
    #  -- file MyModule.fy --
    #  exception MyException
    #      message = 'error'
    #
    #  def run():
    #      raise MyException <- this will be converted to raise MyModule.MyException

    aliases = Elixir.Enum.map(separated_modules, lambda (module_name, _):
        module_name_as_list_of_atoms = module_name
            |> Elixir.String.replace_prefix('Elixir.', '')
            |> Elixir.String.split(".")
            |> Elixir.Enum.map(lambda x: Elixir.String.to_atom(x))

        name_of_module_as_we_want_refer_to = module_name
            |> Elixir.String.split(".")
            |> Elixir.List.last()
            |> Elixir.String.to_atom()

        (
            :alias,
            [],
            [
                (:'__aliases__', [(:alias, False)], module_name_as_list_of_atoms),
                [(:as, (:'__aliases__', [(:alias, False)], [name_of_module_as_we_want_refer_to]))]
            ]
        )
    )

    (:statements, meta, [*aliases, *nodes])

def convert_module(node <- (:statements, meta, body), module_name, config):
    ([module_node], metadata_statements) = Elixir.Enum.split(body, 1)

    case module_node:
        (:struct_def, _, _) -> node |> convert_meta() |> convert_struct_module(module_name, config)
        (:exception, _, _)  -> node |> convert_meta() |> convert_exception_module(module_name, config)

def convert(node, config):
    case Elixir.Kernel.elem(node, 0):
        :number         -> node |> convert_meta() |> convert_number(config)
        :atom           -> node |> convert_meta() |> convert_atom(config)
        :var            -> node |> convert_meta() |> convert_var(config)
        :string         -> node |> convert_meta() |> convert_string(config)
        :regex          -> node |> convert_meta() |> convert_regex(config)
        :charlist       -> node |> convert_meta() |> convert_charlist(config)
        :unary          -> node |> convert_meta() |> convert_unary(config)
        :list           -> node |> convert_meta() |> convert_list(config)
        :tuple          -> node |> convert_meta() |> convert_tuple(config)
        :binop          -> node |> convert_meta() |> convert_binop(config)
        :pattern        -> node |> convert_meta() |> convert_pattern(config)
        :if             -> node |> convert_meta() |> convert_if(config)
        :func           -> node |> convert_meta() |> convert_func(config)
        :statements     -> node |> convert_meta() |> convert_statements(config)
        :lambda         -> node |> convert_meta() |> convert_lambda(config)
        :def            -> node |> convert_meta() |> convert_def_or_defp(config)
        :defp           -> node |> convert_meta() |> convert_def_or_defp(config)
        :static_access  -> node |> convert_meta() |> convert_static_access(config)
        :raise          -> node |> convert_meta() |> convert_raise(config)
        :assert         -> node |> convert_meta() |> convert_assert(config)
        :pipe           -> node |> convert_meta() |> convert_pipe(config)
        :map            -> node |> convert_meta() |> convert_map(config)
        :case           -> node |> convert_meta() |> convert_case(config)
        :call           -> node |> convert_meta() |> convert_call(config)
        :try            -> node |> convert_meta() |> convert_try(config)
        :range          -> node |> convert_meta() |> convert_range_node(config)
        :struct         -> node |> convert_meta() |> convert_struct_node(config)
        # This is temporary, while we dont have this node implemented
        # it's created in the function inject_aliases_of_modules_used_in_module
        # ant it' already converted, so we just return it
        :alias          -> node


def convert_number((:number, _, [value]), _):
    value

def convert_atom((:atom, _, [value]), _):
    Elixir.String.to_atom(value)

def convert_var((:var, _, [_pinned, "True"]), _):
    True

def convert_var((:var, _, [_pinned, "False"]), _):
    False

def convert_var((:var, _, [_pinned, "None"]), _):
    None

def convert_var((:var, meta, [True, value]), _):
    case Elixir.String.contains?(value, "."):
        False -> (:"^", meta, [(Elixir.String.to_atom(value), meta, :Elixir)])
        True -> convert_var_with_dots(value)

def convert_var((:var, meta, [False, value]), _):
    case Elixir.String.contains?(value, "."):
        False -> (Elixir.String.to_atom(value), meta, :Elixir)
        True -> convert_var_with_dots(value)


def convert_var_with_dots(value):
    value
        |> Elixir.String.split('.')
        |> Elixir.Enum.reduce(lambda x, acc:
            prev = case acc:
                (_, _, _) -> acc
                _ -> (Elixir.String.to_atom(acc), [(:if_undefined, :apply)], :Elixir)

            x = Elixir.String.to_atom(x)

            (
                (:".", [], [prev, x]),
                [(:no_parens, True)],
                []
            )
        )


def convert_string((:string, meta, [value]), _):
    value

def convert_regex((:regex, meta, [value]), _):
    (
        :sigil_r,
        Elixir.List.flatten([[(:delimiter, "/")], meta]),
        [(:"<<>>", meta, [value]), []]
    )

def convert_charlist((:charlist, meta, [value]), _):
    Elixir.List.Chars.to_charlist(value)

def convert_unary((:unary, meta, [:minus, node]), config):
    (:"-", meta, [convert(node, config)])

def convert_unary((:unary, meta, [:plus, node]), config):
    (:"+", meta, [convert(node, config)])

def convert_unary((:unary, meta, [:not, node]), config):
    (:"__block__", meta, [(:"!", meta, [convert(node, config)])])

def is_unpack((:unpack, _, _)):
    True

def is_unpack(item):
    False

def convert_list_with_unpack((:list, meta, elements), config):
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
                    (:unpack, meta, [node_to_unpack]) -> convert(node_to_unpack, config)
                    _ -> Elixir.Enum.map(elements_or_unpack, lambda i: convert(i, config))
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

def convert_list(node <- (:list, meta, elements), config):
    case Elixir.Enum.find(elements, &is_unpack/1):
        None -> Elixir.Enum.map(elements, lambda i: convert(i, config))
        _ -> convert_list_with_unpack(node, config)

def convert_tuple((:tuple, meta, elements), config):
    (:"{}", meta, Elixir.Enum.map(elements, lambda i: convert(i, config)))

def convert_binop((:binop, meta, [left, :or, right]), config):
    (:or, meta, [convert(left, config), convert(right, config)])

def convert_binop((:binop, meta, [left, :and, right]), config):
    (:and, meta, [convert(left, config), convert(right, config)])

def convert_binop((:binop, meta, [left, :in, right]), config):
    (:in, meta, [convert(left, config), convert(right, config)])

def convert_binop((:binop, meta, [left, :pow, right]), config):
    ((:".", meta, [:math, :pow]), meta, [convert(left, config), convert(right, config)])

def convert_binop((:binop, meta, [left, op, right]), config):
#    math_module = add_boostrap_prefix(:"Fython.Math", config)

    arguments = [convert(left, config), convert(right, config)]

#    case op:
#        :plus -> ((:".", meta, [math_module, :sum]), meta, arguments)
#        _ ->
    elixir_op = {
        :plus: :"+", :minus: :'-', :mul: :'*', :div: :'/', :gt: :'>',
        :gte: :'>=', :lt: :'<', :lte: :'<=', :ee: :'==', :ne: :'!=', :in: :'in'
    }

    (elixir_op[op], meta, arguments)

def convert_pattern((:pattern, meta, [left, right]), config):
    (:"=", meta, [convert(left, config), convert(right, config)])

def convert_if((:if, meta, [comp_expr, true_case, false_case]), config):
    (:if, meta, [convert(comp_expr, config), [(:do, convert(true_case, config)), (:else, convert(false_case, config))]])

def convert_func((:func, meta, [name, arity]), _):
    (
        :"&",
        meta,
        [(:"/", meta, [(Elixir.String.to_atom(name), meta, :Elixir), arity])]
    )

def convert_statements((:statements, meta, nodes), config):
    content = Elixir.Enum.map(nodes, lambda i: convert(i, config))
    (:"__block__", meta, content)

def convert_lambda((:lambda, meta, [args, statements]), config):
    args = args |> Elixir.Enum.map(lambda i: convert(i, config))

    (:fn, meta, [(:"->", meta, [args, convert(statements, config)])])


def convert_def_or_defp((node_type, meta, [name, args, guards, statements]), config) if node_type in [:def, :defp]:
    args = Elixir.Enum.map(args, lambda i: convert(i, config))

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
                    convert(guard_expr, config)
                ]
            )
        [] -> (Elixir.String.to_atom(name), meta, args)

    (
        node_type,
        meta,
        [
            func_name_quoted,
            [(:do, convert(statements, config))]
        ]
    )

def convert_static_access((:static_access, meta, [node_to_access, node_key]), config):
    (
        (:".", meta, [(:"__aliases__", [(:alias, False)], [:Map]), :fetch!]),
        meta,
        [convert(node_to_access, config), convert(node_key, config)]
    )

def convert_raise((:raise, meta, [expr]), config):
    (:raise, meta, [convert(expr, config)])

def convert_assert((:assert, meta, [expr]), config):
    # Doesnt exist assert in Elixir
    raise_error = (:raise, meta, ["Assertion error"])

    is_false = (:"==", meta, [convert(expr, config), False])
    is_none = (:"==", meta, [convert(expr, config), None])
    is_zero = (:"==", meta, [convert(expr, config), 0])

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

def convert_pipe((:pipe, meta, [left_node, right_node]), config):
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
        |> convert(config)

def is_spread((:spread, _, _)):
    True

def is_spread(item):
    False

def convert_map_with_spread((:map, meta, pairs), config):
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
                    (:spread, meta, [node_to_spread]) -> convert(node_to_spread, config)
                    _ -> (
                        :'%{}',
                        meta,
                        Elixir.Enum.map(
                            pairs_or_spread,
                            lambda (key, value): (convert(key, config), convert(value, config))
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

def convert_map(node <- (:map, meta, pairs), config):
    case Elixir.Enum.find(pairs, &is_spread/1):
        None ->
            pairs = pairs
                |> Elixir.Enum.map(lambda (key, value):
                    (convert(key, config), convert(value, config))
                )

            (:'%{}', meta, pairs)
        _ -> convert_map_with_spread(node, config)

def convert_case((:case, meta, [expr, pairs]), config):

    pairs = pairs
        |> Elixir.Enum.map(lambda (left, right):
            (:"->", meta, [[convert(left, config)], convert(right, config)])
        )

    case expr:
        None -> (:cond, meta, [[(:do, pairs)]])
        _ -> (:case, meta, [convert(expr, config), [(:do, pairs)]])


def convert_call_args(args, keywords, config):
    args = Elixir.Enum.map(args, lambda i: convert(i, config))

    keywords = keywords
        |> Elixir.Enum.map(lambda (key, value):
            [(:key, convert(value, config))]
        )

    Elixir.Enum.concat(args, keywords)


def convert_call((:call, meta, [node_to_call, args, keywords, True]), config):
    arguments = convert_call_args(args, keywords, config)

    (
        (:".", meta, [convert(node_to_call, config)]),
        meta,
        arguments
    )

def convert_call(full <- (:call, meta, [(:var, _, [_, func_name]), args, keywords, False]), config):
    # node_to_call will always be a VarAccessNode on a module call. E.g: Elixir.Map.get

    arguments = convert_call_args(args, keywords, config)

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
                Elixir.String.starts_with?(module, "Fython.") -> module
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

def convert_try((:try, meta, [try_block, exceptions, finally_block]), config):
    do = (:do, convert(try_block, config))

    each_rescue = Elixir.Enum.map(
        exceptions,
        lambda i :
            (except_identifier, alias, block) = i

            # TODO bug, it will return true for alias starting with _ because its the same uppercased
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
                            convert(block, config)
                        ]
                    )
                (True, _) ->
                    # Case of:
                    # > except ArithmeticError as error:

                    except_identifier = Elixir.Enum.join(["Fython.", except_identifier])

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
                            convert(block, config)
                        ]
                    )
    )

    rescue = (:rescue, each_rescue)

    (:try, meta, [[do, rescue]])

def convert_range_node((:range, meta, [left_node, right_node]), config):
    (
        (
            :".",
            meta,
            [(:__aliases__, [(:alias, False)], [Elixir.String.to_atom("Elixir.Range")]), :new]
        ),
        meta,
        [convert(left_node, config), convert(right_node, config)]
    )

def convert_struct_def_node(
    (:struct_def, meta, [struct_name, struct_fields, functions_struct]), config
):
    functions_struct = Elixir.Enum.map(functions_struct, lambda i: convert(i, config))

    required_args = struct_fields
        |> Elixir.Enum.filter(lambda (_, value): value == None)
        |> Elixir.Enum.map(lambda (name, _): Elixir.String.to_atom(name))

    enforce_keys = (:"@", [], [(:enforce_keys, [], [required_args])])

    struct_statements = [
        enforce_keys,
        (
            :defstruct,
            meta,
            [Elixir.Enum.map(
                struct_fields, lambda (n, d):
                    # None means that the field is required
                    converted = case d:
                        None -> None
                        _ -> convert(d, config)

                    (Elixir.String.to_atom(n), converted)
            )]
        ),
        *functions_struct
    ]

    struct_statements


def convert_struct_module((:statements, meta, body), module_name, config):
    ([struct_def_node], metadata_statements) = Elixir.Enum.split(body, 1)
    (:struct_def, _, [struct_name, _, _]) = struct_def_node

    # Functions of struct itself
    struct_statements = struct_def_node |> convert_meta() |> convert_struct_def_node(config)

    # These statements are the functions with metadata info
    metadata_statements = Elixir.Enum.map(metadata_statements, lambda i: convert(i, config))

    module_name = Elixir.Enum.join(['Elixir.', module_name, '.', struct_name])

    (
        module_name,
        (
            :"__block__",
            meta,
            [
                *struct_statements,
                *metadata_statements
            ]
        )
    )


def convert_struct_node((:struct, meta, [struct_name, keywords]), config):
    struct_name = case Elixir.String.starts_with?(struct_name, "Elixir."):
        True -> struct_name
        False -> Elixir.Enum.join(["Fython", ".", struct_name])

    struct_name = Elixir.String.to_atom(struct_name)

    keywords_converted = Elixir.Enum.map(keywords, lambda (key, value):
        (Elixir.String.to_atom(key), convert(value, config))
    )

    (
        :"%",
        meta,
        [
            (:__aliases__, [(:alias, False)], [struct_name]),
            (:"%{}", meta, keywords_converted)
        ]
    )

def convert_exception_module((:statements, meta, body), module_name, config):
    ([exception_node], metadata_statements) = Elixir.Enum.split(body, 1)
    (:exception, _, [exception_name, args]) = exception_node

    module_name = Elixir.Enum.join(['Elixir.', module_name, '.', exception_name])
    exception_name = Elixir.String.to_atom(Elixir.Enum.join(["Fython.", exception_name]))

    required_args = args
        |> Elixir.Enum.filter(lambda (_, value): value == None)
        |> Elixir.Enum.map(lambda (name, _): Elixir.String.to_atom(name))

    enforce_keys = (:"@", [], [(:enforce_keys, [], [required_args])])

    exception_converted = (
        :"defexception",
        meta,
        [Elixir.Enum.map(
            args, lambda (n, d):
                # None means that the field is required
                converted = case d:
                    None -> None
                    _ -> convert(d, config)

                (Elixir.String.to_atom(n), converted)
        )]
    )

    (
        module_name,
        (
            :"__block__",
            meta,
            [enforce_keys, exception_converted]
        )
    )


defp add_boostrap_prefix(module_name, config) if Elixir.Kernel.is_bitstring(module_name):
    add_boostrap_prefix(Elixir.String.to_atom(module_name), config)

defp add_boostrap_prefix(module_name, {"bootstrap_prefix": None}):
    module_name

defp add_boostrap_prefix(module_name, {"bootstrap_prefix": bootstrap_prefix}) if Elixir.Kernel.is_atom(module_name):
    # Elixir.Fython.Module.call -> Elixir.Fython.Bootstrap.Module.call
    # Fython.Module.call        -> Fython.Bootstrap.Module.call
    # Module.call               -> Module.call

    module_name = Elixir.Atom.to_string(module_name)

    case:
        Elixir.String.starts_with?(module_name, "Elixir.Fython") ->
            Elixir.String.replace_prefix(
                module_name,
                "Elixir.Fython",
                Elixir.Enum.join(["Elixir.Fython.", bootstrap_prefix, "."])
            )
        Elixir.String.starts_with?(module_name, "Fython.") ->
            Elixir.String.replace_prefix(
                module_name,
                "Fython.",
                Elixir.Enum.join(["Fython.", bootstrap_prefix, "."])
            )
        True ->
            raise "bootstrap prefix must be placed only in fython calls"

    Elixir.String.to_atom(module_name)