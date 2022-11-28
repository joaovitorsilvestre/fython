def valid_token_type?(type):
    tokens = [
        "INT",
        "STRING",
        "ARROW",
        "LARROW",
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
        "RANGE",
        "EOF"
    ]
    Elixir.Enum.member?(tokens, type)

def keywords():
    [
        'import', 'as', 'and', 'or', 'not', 'if', 'else',
        'def', 'lambda', 'case', 'in', 'raise', 'assert', 'try', 'except', 'finally', 'as',
        'struct'
    ]

def add_eof_token(state):
    tokens = Elixir.Map.get(state, "tokens")

    start_end = case tokens:
        [] -> {"idx": 0, "ln": 0, "col": 0}
        _ -> state["position"]

    add_token(state, "EOF", None, start_end)

def add_token(state, type):
    add_token(state, type, None)

def add_token(state, type, value):
    pos_start = Elixir.Map.get(state, 'position')
    add_token(state, type, value, pos_start)

def add_token(state, type, value, pos_start):
    ident = state["current_ident_level"]
    pos_end = state["position"]

    pos_end = case pos_end['col'] != -1:
        True -> pos_end
        False -> state['prev_position']

    pos_end = pos_end if pos_end != None else pos_start

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
