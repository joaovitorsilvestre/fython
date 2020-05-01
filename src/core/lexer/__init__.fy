def execute(text):
    state = {
        "text": text,
        "position": position(-1, 0, -1),
        "current_ident_level": 0,
        "error": None,
        "current_char": None,
        "tokens": []
    }
    state |> advance() |> parse() |> Core.Lexer.Tokens.add_eof_token()

def position(idx, ln, col):
    {"idx": idx, "ln": ln, "col": col}

def advance(state):
    idx = state |> Map.get("position") |> Map.get("idx")
    ln = state |> Map.get("position") |> Map.get("ln")
    col = state |> Map.get("position") |> Map.get("col")
    text = state |> Map.get("text")

    idx = idx + 1
    current_char = text |> String.at(idx)

    new_pos = case current_char == '\n':
        True -> position(idx, ln + 1, -1)
        False -> position(idx, ln, col + 1)

    new_state = {"position": new_pos, "current_char": current_char}

    Map.merge(state, new_state)

def set_error(state, error):
    Map.put(
        state,
        "error",
        {
            "msg": error,
            "pos_start": Map.get(state, 'position'),
            "pos_end": Map.get(state, 'position')
        }
    )

def parse(state):
    case Map.get(state, "error"):
        None ->
            cc = state |> Map.get("current_char")
            pos = state |> Map.get("position")

            case:
                cc == None -> state
                cc == "#" -> parse(skip_comment(state))
                cc == " " and Map.get(pos, "col") == 0 -> parse(make_ident(state))
                cc == " " or cc == '\t' -> parse(advance(state))
                cc == "\n" ->
                    state
                        |> Map.put("current_ident_level", 0)
                        |> Core.Lexer.Tokens.add_token("NEWLINE")
                        |> advance()
                        |> parse()
                cc == ':' -> parse(make_do_or_token(state))
                cc == "'" or cc == '"' -> parse(make_string(state))
                String.contains?(Core.Lexer.Consts.identifier_chars(True), cc) ->
                    state |> make_identifier() |> parse()
                cc == "&" -> simple_maker(state, "ECOM")
                String.contains?(Core.Lexer.Consts.digists(), cc) -> parse(make_number(state))
                cc == "," -> simple_maker(state, "COMMA")
                cc == "+" -> simple_maker(state, "PLUS")
                cc == '-' -> double_maker(state, "MINUS", ">", "ARROW")
                cc == '*' -> double_maker(state, "MUL", "*", "POW")
                cc == '>' -> double_maker(state, "GT", "=", "GTE")
                cc == '<' -> double_maker(state, "LT", "=", "LTE")
                cc == "+" -> simple_maker(state, "DIV")
                cc == '(' -> simple_maker(state, 'LPAREN')
                cc == ')' -> simple_maker(state, 'RPAREN')
                cc == '[' -> simple_maker(state, 'LSQUARE')
                cc == ']' -> simple_maker(state, 'RSQUARE')
                cc == '{' -> simple_maker(state, 'LCURLY')
                cc == '}' -> simple_maker(state, 'RCURLY')
                cc == '=' -> double_maker(state, "EQ", "=", "EE")
                cc == '!' -> expected_double_maker(state, "!", "NE", "=")
                cc == '|' -> expected_double_maker(state, "|", "PIPE", ">")
                True -> set_error(state, Enum.join(["IllegalCharError: ", cc]))
        _ -> state

def simple_maker(st, type):
    st
        |> Core.Lexer.Tokens.add_token(type)
        |> advance()
        |> parse()

def double_maker(st, type_1, second_char, type_2):
    st = st |> advance()
    cc = Map.get(st, "current_char")

    case:
        cc == second_char -> st |> Core.Lexer.Tokens.add_token(type_2) |> advance() |> parse()
        True -> st |> Core.Lexer.Tokens.add_token(type_1) |> parse()


def expected_double_maker(st, first, type, expected):
    st = st |> advance()
    cc = Map.get(st, "current_char")

    case:
        cc == expected -> st |> Core.Lexer.Tokens.add_token(type) |> advance() |> parse()
        True -> st |> set_error(Enum.join(["Expected '", expected, "' after '", first, "'"]))

def make_ident(state):
    first_char = Map.get(state, "current_char")

    state = loop_while(state, lambda cc:
        cc != None and cc == " "
    )

    total_spaces = Enum.join([first_char, Map.get(state, "result")]) |> String.length()

    state = case rem(total_spaces, 4) != 0:
        True -> set_error(state, "Identation problem")
        False -> state |> Map.put("current_ident_level", max(0, total_spaces))

    state |> Map.delete("result")

def loop_while(st, func):
    st = advance(st)
    cc = Map.get(st, "current_char")
    result = Map.get(st, "result")

    valid = func(cc)

    case valid:
        True -> Map.put(st, "result", Enum.join([result, cc])) |> loop_while(func)
        False -> st


def make_do_or_token(state):
    pos_start = Map.get(state, "position")
    state = advance(state)

    first_char = Map.get(state, "current_char")

    case first_char != None and String.contains?(Core.Lexer.Consts.letters(), first_char):
        True ->
            state = state
                |> Map.put("result",  Map.get(state, "current_char"))
                |> loop_while(lambda cc:
                    cc != None and String.contains?(Core.Lexer.Consts.letters_digits(), cc)
                )
            state = state
                |> Core.Lexer.Tokens.add_token(
                    "ATOM", Map.get(state, "result"), pos_start
                )
                |> Map.delete("result")

            state
        False ->
            state
                |> advance()
                |> Core.Lexer.Tokens.add_token("DO")


def make_string(state):
    pos_start = Map.get(state, "position")
    string_char_type = Map.get(state, "current_char") # ' or "

    state = loop_while(state, lambda cc:
        cc != string_char_type and cc != None
    )

    # to advance the end string char
    state = advance(state)

    state = state
        |> Core.Lexer.Tokens.add_token(
            "STRING", Map.get(state, "result"), pos_start
        )
        |> Map.delete("result")

def skip_comment(state):
    state = advance(state)

    state = loop_while(state, lambda cc:
        cc != '\n'
    )
    Map.delete(state, "result")

def make_number(state):
    pos_start = Map.get(state, "position")
    first_number = Map.get(state, "current_char")

    state = loop_while(state, lambda cc:
        cc != None and String.contains?(Enum.join([Core.Lexer.Consts.digists(), '._']), cc)
    )
    result = Enum.join([first_number, Map.get(state, "result")])

    state = case:
        (String.split(result, ".") |> Enum.count()) > 2 ->
            set_error(state, Enum.join(["IllegalCharError: ."]))
        String.contains?(result, '.') ->
            state
                |> Core.Lexer.Tokens.add_token(
                    "FLOAT", result, pos_start
                )
        True ->
            state
                |> Core.Lexer.Tokens.add_token(
                    "INT", result, pos_start
                )

    state |> Map.delete("result")

def make_identifier(state):
    pos_start = Map.get(state, "position")
    first_char = Map.get(state, "current_char")

    state = loop_while(state, lambda cc:
        cc != None and String.contains?(Core.Lexer.Consts.identifier_chars(False), cc)
    )

    result = Enum.join([first_char, Map.get(state, "result")])

    type = case Enum.member?(Core.Lexer.Tokens.keywords(), result):
        True -> "KEYWORD"
        False -> "IDENTIFIER"

    state
        |> Core.Lexer.Tokens.add_token(type, result, pos_start)
        |> Map.delete("result")