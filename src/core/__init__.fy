def eval_string(text):
    lexed = Core.Lexer.execute(text)

    case Map.get(lexed, "error"):
        None ->
            tokens = Map.get(lexed, "tokens")
            ast = Core.Parser.execute(tokens)

            case Map.get(ast, 'error'):
                None -> ast
                _ -> Core.Errors.Utils.print_error('<stdin>', ast, text)
        _ ->
            Core.Errors.Utils.print_error('<stdin>', lexed, text)
