from fython.core import lex_and_parse
from fython.core.interpreter import Interpreter
from fython.core.interpreter.context import Context
from fython.core.interpreter.symbol_table import SymbolTable
from fython.core.interpreter.types.number import Number

global_symbol_table = SymbolTable()
global_symbol_table.set("None", Number.null)
global_symbol_table.set("True", Number.true)
global_symbol_table.set("False", Number.false)


def run(fn, text):
    ast, error = lex_and_parse(fn, text)
    if error:
        return error

    #interpreter
    interpreter = Interpreter()
    context = Context('<program>')
    context.symbol_table = global_symbol_table
    result = interpreter.visit(ast.node, context)

    return result.value, result.error