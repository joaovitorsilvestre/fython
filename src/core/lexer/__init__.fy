def lexer(text):
    current_char = 0
    current_ident_level = 0
    state = {
        "text": text
        "position": position(0, 1, 0)
    }


def position(idx, ln, col):
    {"idx": idx, "ln": ln, "col": col}

def get_char(text, position):
    text
        |> String.split('\\n')
        |> List.at(ln)
        |> String.at(col)

def advance_col(state):
    idx = state |> Map.get("position") |> Map.get("idx")
    ln = state |> Map.get("position") |> Map.get("ln")
    col = state |> Map.get("position") |> Map.get("col")

    new_pos = position(idx, ln, col)
    {
        "position": new_pos,
        "current_char": get_char(state |> Map.get("text"), new_pos)
    }
