def eval_file(module_name, file_path):
    text = File.read(file_path) |> elem(1)

    eval_string(module_name, text)

def eval_string(module_name, text):
    state_n_converted = Fcore.Generator.Compiler.lexer_parse_convert_file(module_name, text)

    state = Enum.at(state_n_converted, 0)
    converted = Enum.at(state_n_converted, 1)

    case converted:
        None ->
            Fcore.Errors.Utils.print_error('<stdin>', state, text)
            None
        _ ->
            converted
                |> Code.eval_string()
                |> elem(0)
                |> Code.eval_quoted()
                |> elem(0)
