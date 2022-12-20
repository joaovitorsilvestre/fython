def eval_string(string):
    eval_string(string, {"file": 'nofile', 'env': [], 'module_name': 'Nomodule'})

def eval_string(string, config <- {"file": file, "env": env, 'module_name': module_name}):
    (state, [(_, converted, _)]) = Core.Code.lexer_parse_convert_file(module_name, string, config)

    Elixir.Code.eval_quoted(converted, env, [])

def apply(function_name, args) if is_bitstring(function_name):
    function_name
        |> Elixir.String.to_atom()
        |> Elixir.Kernel.apply(args)

def apply(module_name, function_name, args) if is_bitstring(module_name) and is_bitstring(function_name):
    module_name = module_name |> Elixir.String.to_atom()
    function_name = function_name |> Elixir.String.to_atom()

    Elixir.Kernel.apply(module_name, function_name, args)

def exit_with_status(status):
    Erlang.init.stop(status)