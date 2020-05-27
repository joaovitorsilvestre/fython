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
        "PIN",
        "MULLINESTRING",
        "EOF"
    ]
    Elixir.Enum.member?(tokens, type)

def keywords():
    [
        'import', 'as', 'and', 'or', 'not', 'if', 'else',
        'def', 'lambda', 'case', 'in', 'raise', 'try', 'except', 'finally', 'as'
    ]

def add_eof_token(state):
    tokens = Elixir.Map.get(state, "tokens")

    start_end = case tokens:
        [] -> {"idx": 0, "ln": 0, "col": 0}
        _ -> Elixir.Map.get(Elixir.Enum.at(tokens, -1), "pos_end")

    add_token(state, "EOF", None, start_end)

def add_token(state, type):
    add_token(state, type, None)

def add_token(state, type, value):
    pos_start = Elixir.Map.get(state, 'position')
    add_token(state, type, value, pos_start)

def add_token(state, type, value, pos_start):
    ident = state |> Elixir.Map.get("current_ident_level")

    pos_end = state |> Elixir.Map.get("position")

    pos_end = case Elixir.Map.get(pos_end, 'col') != -1:
        True -> pos_end
        False -> Elixir.Map.get(state, 'prev_position')

    case valid_token_type?(type):
        False -> raise Elixir.Enum.join(["Invalid Token Type: ", type])
        True -> None

    token = {
        "type": type,
        "value": value,
        "ident": ident,
        "pos_start": pos_start,
        "pos_end": pos_end
    }

    Elixir.Map.put(state, "tokens", [Elixir.Map.get(state, "tokens"), token] |> Elixir.List.flatten())
