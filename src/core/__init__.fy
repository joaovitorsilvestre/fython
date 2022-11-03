def eval_string(text):
    eval_string('<stdin>', text, {"file": '<stdin>', 'skip_pos_parser': True})

def eval_string(module_name, text, config):
    (state, converted) = Core.Code.lexer_parse_convert_file(module_name, text, config)

    file = Elixir.Map.get(config, 'file')
    env = Elixir.Map.get(config, 'env', [])

    case converted:
        None ->
            Core.Errors.Utils.print_error(file, state, text)
            (None, env)
        _ ->
            try:
                Elixir.Code.eval_quoted(converted, env, [])
            except error:
                Exceptions.format_traceback(error, __STACKTRACE__)
                Elixir.Kernel.reraise(error, __STACKTRACE__)
