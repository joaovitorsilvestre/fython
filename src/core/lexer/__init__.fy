def execute(text):
    state = {
        "text": text,
        "position": position(-1, -1, -1),
        "current_ident_level": 0,
        "error": None,
        "current_char": None,
        "tokens": []
    }
    parse(state)
        |> Core.Lexer.Tokens.add_eof_token()
        |> Map.get("tokens")


def position(idx, ln, col):
    {"idx": idx, "ln": ln, "col": col}

def advance(state):
    idx = state |> Map.get("position") |> Map.get("idx")
    ln = state |> Map.get("position") |> Map.get("ln")
    col = state |> Map.get("position") |> Map.get("col")
    text = state |> Map.get("text")

    idx = idx + 1
    IO.inspect("index")
    IO.inspect(idx)
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
            state = advance(state)

            case  state |> Map.get("current_char"):
                " " -> parse(make_ident(state))
                "\n" ->
                    ident = max(0, Map.get(state, "current_ident_level") - 4)
                    parse(
                        Core.Lexer.Tokens.add_token(state, "TT_NEWLINE")
                    )
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
                False -> state

            state |> Map.delete("total_spaces")
