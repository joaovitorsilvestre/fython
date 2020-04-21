import json
import sys

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


def get_lexed_and_jsonified(file_path):
    file_name = file_path.split('/')[-1].replace('.fy', '')

    with open(file_path, 'r') as f:
        content = f.read()

    ast, error = lex_and_parse(file_name, content)

    def to_json(x):
        try:
            return x.to_json()
        except:
            from fython.core.lexer.tokens import Token
            from fython.core.lexer.position import Position
            if isinstance(x, Position):
                return {"NodeType": x.__class__.__name__, **{k: v for k, v in x.__dict__.items() if k != 'ftxt'}}
            elif isinstance(x, Token):
                return {"NodeType": x.__class__.__name__, **x.__dict__}
            return ""

    return json.dumps(to_json(ast), default=lambda x: to_json(x), indent=2)


if __name__ == '__main__':
    print(get_lexed_and_jsonified(sys.argv[1]))