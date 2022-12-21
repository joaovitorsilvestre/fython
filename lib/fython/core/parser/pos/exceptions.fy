def catch_and_convert_elixir_excetions_to_fython(node, bootstrap_prefix):
    [node, state] = Core.Parser.Traverse.run(node, {
        "bootstrap_prefix": bootstrap_prefix
    }, &add_catch/2)
    node

def add_catch(node <- (node_type, meta, [name, args, guards, statements]), state) if node_type in [:def, :defp]:
    # Inject a try except block around the function body
    # to catch any elixir exceptions and convert them to fython exceptions

    {"bootstrap_prefix": bootstrap_prefix} = state

    error_alias = "elixir_error"

    function_to_call = case bootstrap_prefix:
        None -> "Exception.Conversor.to_fython_exception"
        _ -> Elixir.Enum.join([bootstrap_prefix, ".Exception.Conversor.to_fython_exception"])

    args_call_conversor = [
        (:var, meta, [False, error_alias]),
        (:var, meta, [False, "__STACKTRACE__"])
    ]
    convert_to_fython = (:call, meta, [(:var, meta, [False, function_to_call]), args_call_conversor, [], False])

    reraise_converted = (
        :statements,
        meta,
        [
            (:call, meta, [(:var, meta, [False, "Elixir.Kernel.reraise"]), [
                convert_to_fython, (:var, meta, [False, "__STACKTRACE__"])
            ], [], False])
        ]
    )

    statements = (
        :statements,
        meta,
        [(
            :try,
            meta,
            [statements, [(error_alias, None, reraise_converted)], None]
        )]
    )

    [(node_type, meta, [name, args, guards, statements]), state]

def add_catch(node, state):
    [node, state]