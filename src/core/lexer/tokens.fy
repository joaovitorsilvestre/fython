def valid_token(token):
    tokens = [
        "TT_INT",
        "TT_STRING",
        "TT_ARROW",
        "TT_KEYWORD",
        "TT_IDENTIFIER",
        "TT_ECOM",
        "TT_ATOM",
        "TT_FLOAT",
        "TT_PLUS",
        "TT_MINUS",
        "TT_MUL",
        "TT_DIV",
        "TT_POW",
        "TT_EQ",
        "TT_EE",
        "TT_NE",
        "TT_GT",
        "TT_LT",
        "TT_GTE",
        "TT_LTE",
        "TT_COMMA",
        "TT_DO",
        "TT_LPAREN",
        "TT_RPAREN",
        "TT_LSQUARE",
        "TT_RSQUARE",
        "TT_LCURLY",
        "TT_RCURLY",
        "TT_NEWLINE",
        "TT_PIPE",
        "TT_EOF"
    ]
    List.member?(String.to_atom(token), tokens)

def KEYWORDS():
    [
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
        'case'
    ]
