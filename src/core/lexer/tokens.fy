def valid_token_type?(type):
    tokens = [
        "INT",
        "STRING",
        "ARROW",
        "KEYWORD",
        "IDENTIFIER",
        "ECOM",
        "ATOM",
        "FLOAT",
        "PLUS",
        "MINUS",
        "MUL",
        "DIV",
        "POW",
        "EQ",
        "EE",
        "NE",
        "GT",
        "LT",
        "GTE",
        "LTE",
        "COMMA",
        "DO",
        "LPAREN",
        "RPAREN",
        "LSQUARE",
        "RSQUARE",
        "LCURLY",
        "RCURLY",
        "NEWLINE",
        "PIPE",
        "EOF"
    ]
    Enum.member?(tokens, type)

def keywords():
    [
        'import', 'from', 'as', 'and', 'or', 'not', 'if', 'elif', 'else',
        'def', 'lambda', 'return', 'case'
    ]

def add_eof_token(state):
    state |> add_token("EOF", None, None)

def add_token(state, type):
    add_token(state, type, None)

def add_token(state, type, value):
    pos_start = Map.get(state, 'position')
    add_token(state, type, value, pos_start)

def add_token(state, type, value, pos_start):
    ident = state |> Map.get("current_ident_level")
    pos_end = state |> Map.get("position")

    case valid_token_type?(type):
        False -> raise Enum.join(["Invalid Token Type: ", type])
        True -> None

    token = {
        "type": type,
        "value": value,
        "ident": ident,
        "pos_start": pos_start,
        "pos_end": pos_end,
    }

    Map.put(state, "tokens", [Map.get(state, "tokens"), token] |> List.flatten())
