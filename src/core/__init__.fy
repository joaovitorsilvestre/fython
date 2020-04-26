def eval_string(text):
    lexed = Core.Lexer.execute(text)

    case Enum.at(lexed, 0):
        :ok ->
            tokens = Enum.at(lexed, 1) |> Map.get("tokens")
            ast = Core.Parser.execute(tokens)
            ast
        :error ->
            Enum.at(lexed, 1)

