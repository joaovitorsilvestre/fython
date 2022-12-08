def format_error_in_source_code(source_code, meta):
    source_code_lines = Elixir.String.split(source_code, '\n')
    source_code_lines_indexed = source_code_lines
        |> Elixir.Enum.with_index()

    (_, line_num, start_col) = meta['start']
    (_, _, end_col) = meta['end']

    state = {
        "source_code": source_code,
        "source_code_lines": source_code_lines,
        "source_code_lines_indexed": source_code_lines_indexed,
        "position": (line_num, start_col, end_col),  # line starting at 0
    }

    lines_above = get_lines_above_error(state)
    pointers = draw_pointers(state)
    current_line = Elixir.Enum.at(state['source_code_lines_indexed'], line_num)

    lines_formated = [
        *add_line_numbers(state, lines_above),
        *add_line_numbers(state, [current_line]),
        *pointers,
    ]

    Elixir.Enum.join(lines_formated, '\n')


def get_lines_above_error(state):
    HOW_MANY_LINES_SHOW_ABOVE = 5

    (line_num, _, _) = state['position']

    source_code_lines = state['source_code_lines_indexed']

    range_to_slice = case line_num > HOW_MANY_LINES_SHOW_ABOVE:
        True -> (line_num - HOW_MANY_LINES_SHOW_ABOVE)..(line_num - 1)
        False -> 0..(line_num - 1)

    lines_to_keep_above = Elixir.Enum.slice(source_code_lines, range_to_slice)


def draw_pointers(state):
    (_, start_col, end_col) = state['position']

    pointer = Elixir.String.duplicate(" ", get_necessary_size_to_fit_line_numbers(state) + 3)

    pointer = Elixir.Enum.join([
        pointer, Elixir.String.duplicate("~", start_col + 1)
    ])

    num_of_up = case end_col - start_col:
        0 -> 1
        _ -> end_col - start_col

    pointer = Elixir.Enum.join([
        pointer, Elixir.String.duplicate("^", num_of_up)
    ])

    [pointer]


def get_necessary_size_to_fit_line_numbers({"position": (line_num, _, _)}):
    line_num + 1
        |> Elixir.Integer.to_string()
        |> Elixir.String.length()


def add_line_numbers(state, list_of_lines_indexed):
    size = get_necessary_size_to_fit_line_numbers(state)

    list_of_lines_indexed
        |> Elixir.Enum.map(lambda (line, i):
            line_number = Elixir.Integer.to_string(i + 1) |> Elixir.String.pad_leading(size)
            Elixir.Enum.join([' ', line_number, ' | ', line])
        )
