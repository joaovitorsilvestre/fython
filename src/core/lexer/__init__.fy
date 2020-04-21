import Code.Lexer.Tokens

def execute(text):
    state = {
        "text": text,
        "position": position(-1, 0, -1),
        "current_ident_level": 0,
        "error": None,
        "current_char": None,
        "tokens": []
    }
    parse(state) |> Map.get("tokens")

def position(idx, ln, col):
    {"idx": idx, "ln": ln, "col": col}

def advance(state):
    idx = state |> Map.get("position") |> Map.get("idx")
    ln = state |> Map.get("position") |> Map.get("ln")
    col = state |> Map.get("position") |> Map.get("col")
    text = state |> Map.get("text")

    number_of_lines = String.split(text, "\n") |> Enum.count()
    number_of_cols = String.split(text, "\n")
        |> Enum.at(ln, "")
        |> String.length()

    to_sum = case col + 1 >= number_of_cols:
        True -> 'ln'
        False -> 'col'

    ln = ln + 1 if to_sum == 'ln' else ln
    col = col + 1 if to_sum == 'col' else col

    new_pos = position(idx, ln, col)

    current_char = case ln > number_of_lines or col > number_of_cols:
        True -> None
        False -> text |> String.split('\\n') |> Enum.at(ln) |> String.at(col)

    new_state = {"position": new_pos, "current_char": current_char}

    Map.merge(state, new_state)

def set_error(state, error):
    Map.put(state, "error", error)

def parse(state):
    case Map.get(state, "error"):
        None ->
            state = advance(state)

            case  state |> Map.get("current_char"):
                ' ' -> parse(make_ident(state))
                '\n' ->
                    ident = Integer.max(0, Map.get("current_ident_level") - 4)
                    Code.Lexer.Tokens.add_token(state, "")
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
