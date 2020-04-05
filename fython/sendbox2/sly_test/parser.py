from pprint import pprint

from sly import Parser

from fython.sly_test.lexer import BasicLexer


class BasicParser(Parser):
    tokens = BasicLexer.tokens

    precedence = (
        ('left', '+', '-'),
        ('left', '*', '/'),
        ('right', 'UMINUS'),
    )

    def __init__(self):
        self.env = { }
    @_('')
    def statement(self, p):
        pass

    @_('LMAP expr RMAP')
    def expr(self, p):
        return p.expr

    @_('LPAREN expr RPAREN')
    def expr(self, p):
        return p.expr

    @_('FUN NAME "(" ")" DO statement')
    def statement(self, p):
        return ('fun_def', p.NAME, p.statement)

    @_('NAME "(" ")"')
    def statement(self, p):
        return ('fun_call', p.NAME)

    @_('var_assign')
    def statement(self, p):
        return p.var_assign

    @_('NAME "=" expr')
    def var_assign(self, p):
        return ('var_assign', p.NAME, p.expr)

    @_('NAME "=" STRING')
    def var_assign(self, p):
        return ('var_assign', p.NAME, p.STRING)

    @_('expr')
    def statement(self, p):
        return (p.expr)

    @_('expr "+" expr')
    def expr(self, p):
        return ('add', p.expr0, p.expr1)

    @_('expr "-" expr')
    def expr(self, p):
        return ('sub', p.expr0, p.expr1)

    @_('expr "*" expr')
    def expr(self, p):
        return ('mul', p.expr0, p.expr1)

    @_('expr "/" expr')
    def expr(self, p):
        return ('div', p.expr0, p.expr1)

    @_('"-" expr %prec UMINUS')
    def expr(self, p):
        return p.expr

    @_('NAME')
    def expr(self, p):
        return ('var', p.NAME)

    @_('NUMBER')
    def expr(self, p):
        return ('num', p.NUMBER)


    def error(self, t):
        print("Illegal character '%s'" % t.value[0])
        print(t)

if __name__ == '__main__':
    lexer = BasicLexer()
    parser = BasicParser()
    env = {}
    while True:
        try:
            text = input('fyton > ')
        except EOFError:
            break
        if text:
            tree = parser.parse(lexer.tokenize(text))
            pprint(tree)
