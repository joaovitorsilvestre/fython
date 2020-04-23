def execute(text):
    state = {
        "text": text,
        "position": position(-1, 0, -1),
        "current_ident_level": 0,
        "error": None,
        "current_char": None,
        "tokens": []
    }
    state
        |> advance()
        |> parse()
        |> Core.Lexer.Tokens.add_eof_token()

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
        True -> position(idx, ln + 1, 0)
        False -> position(idx, ln, col + 1)

    new_state = {"position": new_pos, "current_char": current_char}

    Map.merge(state, new_state)

def set_error(state, error):
    Map.put(state, "error", error)

def parse(state):
    case Map.get(state, "error"):
        None ->
            case state |> Map.get("current_char"):
                " " -> parse(make_ident(state))
                "\n" ->
                    state
                        |> Map.put("current_ident_level", 0)
                        |> Core.Lexer.Tokens.add_token("TT_NEWLINE")
                        |> advance()
                        |> parse()
                '\t' -> parse(advance(state))
                ':' -> parse(make_do_or_token(state))
                None -> state
        _ -> state


def make_ident(state):
    current_char = state |> Map.get("current_char")
    total_spaces = Map.get(state, "total_spaces", 0)

    case current_char == " ":
        True ->
            advance(state)
                |> Map.put("total_spaces", total_spaces + 1)
                |> make_ident()
        False ->
            total_spaces = Map.fetch(state, "total_spaces") |> elem(1)

            state = case rem(total_spaces, 4) != 0:
                True -> set_error(state, "Identation problem")
                False -> state |> Map.put("current_ident_level", max(0, total_spaces))

            state |> Map.delete("total_spaces")

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

    case String.contains?(Core.Lexer.Consts.letters(), Map.get(state, "current_char")):
        True ->
            state = state
                |> Map.put("result",  Map.get(state, "current_char"))
                |> loop_while(lambda cc:
                    cc != None and String.contains?(Core.Lexer.Consts.letters_digits(), cc)
                )
            state = state
                |> Core.Lexer.Tokens.add_token(
                    "TT_ATOM", Map.get(state, "result"), pos_start
                )
                |> Map.delete("result")

            state
        False ->
            state
                |> advance
                |> Core.Lexer.Tokens.add_token("TT_DO")
