def format_error_in_source_code(source_code, meta):
    # 5 Lines above as default and no left padding
    format_error_in_source_code(source_code, meta, 5, "")

def format_error_in_source_code(source_code, meta, lines_to_show_above, left_padding):
    source_code_lines = Elixir.String.split(source_code, '\n')
    source_code_lines_indexed = source_code_lines
        |> Elixir.Enum.with_index()

    (_, line_num, start_col) = meta['start']
    (_, line_num_end, end_col) = meta['end']

    state = {
        "source_code": source_code,
        "source_code_lines": source_code_lines,
        "source_code_lines_indexed": source_code_lines_indexed,
        "position": (line_num, start_col, end_col),  # line starting at 0
    }

    # TODO we dont suport showing multiline errors, yet, here do a patch to not break in that case
    # TODO For now, we will show from first col to the end of the first line
    end_col = case line_num != line_num_end do
        True -> Elixir.String.length(Elixir.Enum.at(source_code_lines, line_num)) - 1
        False -> end_col

    lines_above = get_lines_above_error(state, lines_to_show_above)
    pointers = draw_pointers(state, start_col, end_col)
    current_line = Elixir.Enum.at(state['source_code_lines_indexed'], line_num)

    lines_formated = [
        *add_line_numbers(state, lines_above),
        *add_line_numbers(state, [current_line]),
        *pointers,
    ]

    lines_formated
        |> Elixir.Enum.map(lambda x: Elixir.Enum.join([left_padding, x]))
        |> Elixir.Enum.join('\n')


def get_lines_above_error(state, lines_to_show_above):
    (line_num, _, _) = state['position']

    source_code_lines = state['source_code_lines_indexed']

    range_to_slice = case line_num > lines_to_show_above:
        True -> (line_num - lines_to_show_above)..(line_num - 1)
        False -> 0..(line_num - 1)

    lines_to_keep_above = Elixir.Enum.slice(source_code_lines, range_to_slice)


def draw_pointers(state, start_col, end_col):
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
