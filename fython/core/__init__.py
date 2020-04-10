from fython.core.lexer.lexer import Lexer
from fython.core.parser import Parser


def lex_and_parse(filename, text):
    # generate tokens
    lexer = Lexer(filename, text)
    tokens, error = lexer.make_tokens()
    if error:
        return None, error

    # generate AST
    parser = Parser(tokens)
    ast = parser.parse()
    if ast.error:
        return None, ast.error

    return ast.node, ast.error