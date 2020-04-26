def eval_string(text):
    lexed = Core.Lexer.execute(text)

    ast = Core.Parser.execute(lexed)