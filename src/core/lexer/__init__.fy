def execute(text):
    state = {
        "text": text,
        "position": position(-1, 0, -1),
        "prev_position": None,
        "current_ident_level": 0,
        "error": None,
        "current_char": None,
        "tokens": []
    }

    result = state |> advance() |> parse() |> Core.Lexer.Tokens.add_eof_token()

    result

def position(idx, ln, col):
    {"idx": idx, "ln": ln, "col": col}

def advance(state):
    idx = state |> Elixir.Map.get("position") |> Elixir.Map.get("idx")
    ln = state |> Elixir.Map.get("position") |> Elixir.Map.get("ln")
    col = state |> Elixir.Map.get("position") |> Elixir.Map.get("col")
    text = state |> Elixir.Map.get("text")

    prev_position = Elixir.Map.get(state, 'position')

    idx = idx + 1
    current_char = text |> Elixir.String.at(idx)

    new_pos = case current_char == '\n':
        True -> position(idx, ln + 1, -1)
        False -> position(idx, ln, col + 1)

    new_state = {
        "position": new_pos,
        "prev_position": prev_position,
        "current_char": current_char
    }

    Elixir.Map.merge(state, new_state)

def set_error(state, error):
    Elixir.Map.put(
        state,
        "error",
        {
            "msg": error,
            "pos_start": Elixir.Map.get(state, 'position'),
            "pos_end": Elixir.Map.get(state, 'position')
        }
    )

def parse(state):
    case Elixir.Map.get(state, "error"):
        None ->
            cc = state |> Elixir.Map.get("current_char")
            pos = state |> Elixir.Map.get("position")

            case:
                cc == None -> state
                cc == "#" -> parse(skip_comment(state))
                cc == " " and Elixir.Map.get(pos, "col") == 0 -> parse(make_ident(state))
                cc == " " or cc == '\t' -> parse(advance(state))
                cc == "\n" ->
                    state
                        |> Elixir.Map.put("current_ident_level", 0)
                        |> Core.Lexer.Tokens.add_token("NEWLINE")
                        |> advance()
                        |> parse()
                cc == ':' -> parse(make_do_or_token(state))
                cc == "'" or cc == '"' -> parse(make_string(state))
                Elixir.String.contains?(Core.Lexer.Consts.identifier_chars(True), cc) ->
                    state |> make_identifier() |> parse()
                cc == "&" -> simple_maker(state, "ECOM")
                Elixir.String.contains?(Core.Lexer.Consts.digists(), cc) -> parse(make_number(state))
                cc == "^" -> simple_maker(state, "PIN")
                cc == "," -> simple_maker(state, "COMMA")
                cc == "+" -> simple_maker(state, "PLUS")
                cc == '-' -> double_maker(state, "MINUS", ">", "ARROW")
                cc == '*' -> double_maker(state, "MUL", "*", "POW")
                cc == "/" -> simple_maker(state, "DIV")
                cc == '>' -> double_maker(state, "GT", "=", "GTE")
                cc == '<' -> double_maker(state, "LT", "=", "LTE")
                cc == '(' -> simple_maker(state, 'LPAREN')
                cc == ')' -> simple_maker(state, 'RPAREN')
                cc == '[' -> simple_maker(state, 'LSQUARE')
                cc == ']' -> simple_maker(state, 'RSQUARE')
                cc == '{' -> simple_maker(state, 'LCURLY')
                cc == '}' -> simple_maker(state, 'RCURLY')
                cc == '=' -> double_maker(state, "EQ", "=", "EE")
                cc == '!' -> expected_double_maker(state, "!", "NE", "=")
                cc == '|' -> expected_double_maker(state, "|", "PIPE", ">")
                True -> set_error(state, Elixir.Enum.join(["IllegalCharError: ", cc]))
        _ -> state

def simple_maker(st, type):
    st
        |> Core.Lexer.Tokens.add_token(type)
        |> advance()
        |> parse()

def double_maker(st, type_1, second_char, type_2):
    st = st |> advance()
    cc = Elixir.Map.get(st, "current_char")

    case:
        cc == second_char -> st |> Core.Lexer.Tokens.add_token(type_2) |> advance() |> parse()
        True -> st |> Core.Lexer.Tokens.add_token(type_1) |> parse()


def expected_double_maker(st, first, type, expected):
    st = st |> advance()
    cc = Elixir.Map.get(st, "current_char")

    case:
        cc == expected -> st |> Core.Lexer.Tokens.add_token(type) |> advance() |> parse()
        True -> st |> set_error(Elixir.Enum.join(["Expected '", expected, "' after '", first, "'"]))

def make_ident(state):
    first_char = Elixir.Map.get(state, "current_char")

    state = loop_while(state, lambda cc:
        cc != None and cc == " "
    )

    total_spaces = Elixir.Enum.join([first_char, Elixir.Map.get(state, "result")]) |> Elixir.String.length()

    state = case rem(total_spaces, 4) != 0:
        True -> set_error(state, "Identation problem")
        False -> state |> Elixir.Map.put("current_ident_level", max(0, total_spaces))

    state |> Elixir.Map.delete("result")

def loop_while(st, func):
    st = advance(st)
    cc = Elixir.Map.get(st, "current_char")
    result = Elixir.Map.get(st, "result")

    valid = func(cc)

    case valid:
        True -> Elixir.Map.put(st, "result", Elixir.Enum.join([result, cc])) |> loop_while(func)
        False -> st


def make_do_or_token(state):
    pos_start = Elixir.Map.get(state, "position")
    state = advance(state)

    first_char = Elixir.Map.get(state, "current_char")

    case first_char != None and Elixir.String.contains?(Core.Lexer.Consts.letters(), first_char):
        True ->
            state = state
                |> Elixir.Map.put("result",  Elixir.Map.get(state, "current_char"))
                |> loop_while(lambda cc:
                    cc != None and Elixir.String.contains?(Core.Lexer.Consts.letters_digits(), cc)
                )
            state = state
                |> Core.Lexer.Tokens.add_token(
                    "ATOM", Elixir.Map.get(state, "result"), pos_start
                )
                |> Elixir.Map.delete("result")

            state
        False ->
            state
                |> advance()
                |> Core.Lexer.Tokens.add_token("DO")


def make_string(state):
    pos_start = Elixir.Map.get(state, "position")
    string_char_type = Elixir.Map.get(state, "current_char") # ' or "

    state = loop_while(state, lambda cc:
        cc != string_char_type and cc != None
    )

    # to advance the end string char
    state = advance(state)

    string = state
        |> Elixir.Map.get("result", "")
        |> Elixir.String.graphemes()
        |> Elixir.Enum.map(lambda i:
            Elixir.Enum.join(['\\', '"']) if i == '"' else i
        )
        |> Elixir.Enum.join()

    state
        |> Core.Lexer.Tokens.add_token(
            "STRING", string, pos_start
        )
        |> Elixir.Map.delete("result")

def skip_comment(state):
    state = advance(state)

    state = loop_while(state, lambda cc:
        cc != '\n'
    )
    Elixir.Map.delete(state, "result")

def make_number(state):
    pos_start = Elixir.Map.get(state, "position")
    first_number = Elixir.Map.get(state, "current_char")

    state = loop_while(state, lambda cc:
        cc != None and Elixir.String.contains?(Elixir.Enum.join([Core.Lexer.Consts.digists(), '._']), cc)
    )
    result = Elixir.Enum.join([first_number, Elixir.Map.get(state, "result")])

    state = case:
        (Elixir.String.split(result, ".") |> Elixir.Enum.count()) > 2 ->
            set_error(state, Elixir.Enum.join(["IllegalCharError: ."]))
        Elixir.String.contains?(result, '.') ->
            state
                |> Core.Lexer.Tokens.add_token(
                    "FLOAT", result, pos_start
                )
        True ->
            state
                |> Core.Lexer.Tokens.add_token(
                    "INT", result, pos_start
                )

    state |> Elixir.Map.delete("result")

def make_identifier(state):
    pos_start = Elixir.Map.get(state, "position")
    first_char = Elixir.Map.get(state, "current_char")

    state = loop_while(state, lambda cc:
        cc != None and Elixir.String.contains?(Core.Lexer.Consts.identifier_chars(False), cc)
    )

    result = Elixir.Enum.join([first_char, Elixir.Map.get(state, "result")])

    type = case Elixir.Enum.member?(Core.Lexer.Tokens.keywords(), result):
        True -> "KEYWORD"
        False -> "IDENTIFIER"

    state
        |> Core.Lexer.Tokens.add_token(type, result, pos_start)
        |> Elixir.Map.delete("result")