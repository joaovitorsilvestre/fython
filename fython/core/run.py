from fython.core.interpreter import Interpreter
from fython.core.interpreter.context import Context
from fython.core.interpreter.symbol_table import SymbolTable
from fython.core.interpreter.types.number import Number
from fython.core.lexer.lexer import Lexer
from fython.core.parser import Parser

global_symbol_table = SymbolTable()
global_symbol_table.set("None", Number.null)
global_symbol_table.set("True", Number.true)
global_symbol_table.set("False", Number.false)


def run(fn, text):
    # generate tokens
    lexer = Lexer(fn, text)
    tokens, error = lexer.make_tokens()
    if error:
        return None, error

    # generate AST
    parser = Parser(tokens)
    ast = parser.parse()
    if ast.error: return None, ast.error
    #return ast.node, ast.error

    #interpreter
    interpreter = Interpreter()
    context = Context('<program>')
    context.symbol_table = global_symbol_table
    result = interpreter.visit(ast.node, context)

    return result.value, result.error