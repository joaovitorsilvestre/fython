def eval_file(module_name, file_path):
    text = Elixir.File.read(file_path) |> Elixir.Kernel.elem(1)

    eval_string(module_name, text)

def eval_string(module_name, text):
    eval_string(module_name, text, [])

def eval_string(module_name, text, bindings):
    eval_string(module_name, text, bindings, [])

def eval_string(module_name, text, bindings, env):
    state_n_converted = Core.Code.lexer_parse_convert_file(module_name, "<stdin>", text, bindings)

    state = Elixir.Enum.at(state_n_converted, 0)
    converted = Elixir.Enum.at(state_n_converted, 1)

    case converted:
        None ->
            Core.Errors.Utils.print_error('<stdin>', state, text)
            (None, env)
        _ ->
#            Elixir.IO.inspect(converted)
            try:
                Elixir.Code.eval_quoted(converted, bindings, env)
            except error:
                Elixir.IO.inspect('ennv')
                Elixir.IO.inspect(env)
                Exceptions.format_traceback(error, __STACKTRACE__)
                Elixir.Kernel.reraise(error, __STACKTRACE__)

