def eval_string(text):
    eval_string('<stdin>', text, {"file": '<stdin>', 'env': []})

def eval_string(module_name, text, config <- {"file": file, "env": env}):
    (state, [(_, converted)]) = Core.Code.lexer_parse_convert_file(module_name, text, config)

    Elixir.Code.eval_quoted(converted, env, [])

def exit_with_status(status):
    Erlang.init.stop(status)