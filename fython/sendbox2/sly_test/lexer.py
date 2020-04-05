from sly import Lexer


class BasicLexer(Lexer):
    tokens = { NAME, NUMBER, STRING, FUN, DO,
               LPAREN, RPAREN,
               LMAP, RMAP}
    ignore = '\t '

    literals = { '=', '+', '-', '/', '*', ',', ';' }

    # Define tokens
    FUN = r'def'
    DO = r':'
    NAME = r'[a-zA-Z_][a-zA-Z0-9_]*'
    STRING = r'\".*?\"'
    LPAREN  = r'\('
    RPAREN  = r'\)'

    LMAP = "\{"
    RMAP = "\}"

    @_(r'\d+')
    def NUMBER(self, t):
        t.value = int(t.value)
        return t

    @_(r'#.*')
    def COMMENT(self, t):
        pass

    @_(r'\n+')
    def newline(self,t ):
        self.lineno = t.value.count('\n')
