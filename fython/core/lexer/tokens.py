TT_INT              = 'INT'
TT_STRING           = 'STRING'
TT_ARROW            = 'ARROW'
TT_KEYWORD          = 'KEYWORD'
TT_IDENTIFIER       = 'IDENTIFIER'
TT_ECOM             = 'ECOM'
TT_ATOM             = 'TT_ATOM'
TT_FLOAT            = "FLOAT"
TT_PLUS             = 'PLUS'
TT_MINUS            = "MINUS"
TT_MUL              = "MUL"
TT_DIV              = "DIV"
TT_POW              = "POW"
TT_EQ               = "EQ"
TT_EE               = "EE"
TT_NE               = "NE"
TT_GT               = "GT"
TT_LT               = "LT"
TT_GTE              = "GTE"
TT_LTE              = "LTE"
TT_COMMA            = "COMMA"
TT_DO               = "DO"
TT_LPAREN           = "LPAREN"
TT_RPAREN           = "RPAREN"
TT_LSQUARE          = "LSQUARE"
TT_RSQUARE          = "RSQUARE"
TT_LCURLY           = "LCURLY"
TT_RCURLY           = "RCURLY"
TT_NEWLINE          = 'NEWLINE'
TT_PIPE             = 'PIPE'
TT_EOF              = 'EOF'

# True, False and None are treated as identifiers
# We just care about they in the convert to elixir ast part

KEYWORDS = [
    'import',
    'from',
    'as',
    'and',
    'or',
    'not',
    'if',
    'elif',
    'else',
    'def',
    'lambda',
    'return',
    'case',
    'in',
    'raise'
]


class Token:
    def __init__(self, type, ident, value=None, pos_start=None, pos_end=None):
        self.type = type
        self.value = value
        self.ident = ident
        if pos_start:
            self.pos_start = pos_start.copy()
            self.pos_end = pos_start.copy()
            self.pos_end.advance()

        if pos_end:
            self.pos_end = pos_end

    def matches(self, type_, value):
        return self.type == type_ and self.value == value

    def __repr__(self):
        if self.value is not None:
            return f'{self.type}:{self.value}'
        return self.type


    def debug_me(self):
        from fython.core.parser.utils import string_with_arrows
        print(string_with_arrows(self.pos_start.ftxt, self.pos_start, self.pos_end))

