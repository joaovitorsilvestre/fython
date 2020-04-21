def execute(text):
    state = {
        "text": text,
        "position": position(-1, 0, -1),
        "current_ident_level": 0,
        "tokens": []
    }
    parse(state)

def position(idx, ln, col):
    {"idx": idx, "ln": ln, "col": col}

def add_token(state, token):
    Map.put(state, "tokens", [Map.get(state, "tokens"), token] |> List.flatten())

def get_char(state):
    text = state |> Map.get("text")
    position = state |> Map.get("position")
    get_char(text, position)

def get_char(text, position):
    ln = position |> Map.get("ln")
    col = position |> Map.get("col")

    number_of_lines = String.split(text, "\n") |> Enum.count()
    number_of_cols = String.split(text, "\n")
        |> Enum.at(ln)
        |> String.graphemes()
        |> Enum.count()

    case ln > number_of_lines or col > number_of_cols:
        True -> None
        False -> text |> String.split('\\n') |> Enum.at(ln) |> String.at(col)

def advance_line(state):
    idx = state |> Map.get("position") |> Map.get("idx")
    ln = state |> Map.get("position") |> Map.get("ln")
    col = state |> Map.get("position") |> Map.get("col")

    new_pos = position(idx, ln + 1, col)
    new_state = {
        "position": new_pos,
        "current_char": get_char(state |> Map.get("text"), new_pos)
    }

    Map.merge(
        state, new_state
    )

def advance_col(state):
    idx = state |> Map.get("position") |> Map.get("idx")
    ln = state |> Map.get("position") |> Map.get("ln")
    col = state |> Map.get("position") |> Map.get("col")

    new_pos = position(idx, ln, col + 1)
    new_state = {
        "position": new_pos,
        "current_char": get_char(state |> Map.get("text"), new_pos)
    }

    Map.merge(
        state, new_state
    )

def parse(state):
    state = advance_col(state)
    char = get_char(state)
