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

def add_token(state, type):
    add_token(state, type, ident, None)

def add_token(state, type, value):
    pos_start = Map.get("pos_start")
    pos_end = Map.get("pos_end")

    add_token(state, type, value, pos_start, pos_end)

def add_token(state, type, value, pos_start, pos_end):
    ident = state |> Map.get("current_ident_level")

    token = {
        "type": type,
        "value": value,
        "ident": ident,
        "pos_start": pos_start,
        "pos_end": pos_end,
    }

    Map.put(state, "tokens", [Map.get(state, "tokens"), token] |> List.flatten())
