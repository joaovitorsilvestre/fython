def eval_file(module_name, file_path):
    text = Elixir.File.read(file_path) |> Elixir.Kernel.elem(1)

    eval_string(module_name, text)

def eval_string(module_name, text):
    state_n_converted = Core.Generator.Compiler.lexer_parse_convert_file(module_name, text)

    state = Elixir.Enum.at(state_n_converted, 0)
    converted = Elixir.Enum.at(state_n_converted, 1)

    case converted:
        None ->
            Core.Errors.Utils.print_error('<stdin>', state, text)
            None
        _ ->
            converted
                |> Elixir.Code.eval_string()
                |> Elixir.Kernel.elem(0)
                |> Elixir.Code.eval_quoted()
                |> Elixir.Kernel.elem(0)
