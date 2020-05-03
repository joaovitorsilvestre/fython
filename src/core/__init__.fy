def eval_file(module_name, file_path):
    text = File.read(file_path) |> elem(1)

    eval_string(module_name, text)

def eval_string(module_name, text):
    lexed = Core.Lexer.execute(text)

    case Map.get(lexed, "error"):
        None ->
            tokens = Map.get(lexed, "tokens")
            Core.Parser.execute(tokens)
        _ ->
            lexed

