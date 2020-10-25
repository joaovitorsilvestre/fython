def eval_file(module_name, file_path):
    text = Elixir.File.read(file_path) |> Elixir.Kernel.elem(1)

    eval_string(module_name, text)

def eval_string(module_name, text):
    eval_string(module_name, text, [])

def eval_string(module_name, text, env):
    state_n_converted = Core.Code.lexer_parse_convert_file(module_name, "<stdin>", text, env)

    state = Elixir.Enum.at(state_n_converted, 0)
    converted = Elixir.Enum.at(state_n_converted, 1)

    case converted:
        None ->
            Core.Errors.Utils.print_error('<stdin>', state, text)
            (None, env)
        _ ->
            Elixir.IO.inspect(converted)

            # (result, new_env)
            try:
                converted |> Elixir.Code.eval_quoted(env)
            except Elixir.CompileError as e:
#                Elixir.IO.inspect(e)
                (None, env)
