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
        'import', 'as', 'and', 'or', 'not', 'if', 'else',
        'def', 'lambda', 'case', 'in', 'raise'
    ]

def add_eof_token(state):
    tokens = Map.get(state, "tokens")

    start_end = case tokens:
        [] -> {"idx": 0, "ln": 0, "col": 0}
        _ -> Map.get(Enum.at(tokens, -1), "pos_end")

    add_token(state, "EOF", None, start_end)

def add_token(state, type):
    add_token(state, type, None)

def add_token(state, type, value):
    pos_start = Map.get(state, 'position')
    add_token(state, type, value, pos_start)

def add_token(state, type, value, pos_start):
    ident = state |> Map.get("current_ident_level")

    pos_end = state |> Map.get("position")

    pos_end = case Map.get(pos_end, 'col') != -1:
        True -> pos_end
        False -> Map.get(state, 'prev_position')

    token = {
        "type": type,
        "value": value,
        "ident": ident,
        "pos_start": pos_start,
        "pos_end": pos_end
    }

    case valid_token_type?(type):
        False -> raise Enum.join(["Invalid Token Type: ", type])
        True -> None

    Map.put(state, "tokens", [Map.get(state, "tokens"), token] |> List.flatten())
