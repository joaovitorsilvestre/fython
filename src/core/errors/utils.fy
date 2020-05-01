def print_error(module_name, state, text):
    # support to show errors of lexer and parser

    guide = string_with_arrows(state, text)

    Enum.join([
        'File: ', module_name,
        ', line: ',
        Map.get(state, "error") |> Map.get('pos_start') |> Map.get('ln'),
        '\n\n', guide, '\n\n',
        Map.get(state, "error") |> Map.get('msg')
    ])
        |> IO.puts()

def string_with_arrows(state, text):
    error = Map.get(state, "error")
    pos_start = Map.get(error, 'pos_start')
    pos_end = Map.get(error, 'pos_end')

    lines = String.split(text, '\n')

    lines_with_error = Range.new(pos_start |> Map.get('ln'), pos_end |> Map.get('ln'))

    col_range_per_line = Range.new(0, Enum.count(lines) - 1)
        |> Enum.map(lambda ln:
            case:
                ln in lines_with_error ->
                    case:
                        ln == 0 ->
                            [Map.get(pos_start, 'col'), String.length(Enum.at(lines, 0)) - 1]
                        ln == Enum.at(lines_with_error, -1) ->
                            [0, Map.get(pos_end, 'col')]
                        True -> [0, String.length(Enum.at(lines, 0)) - 1]
                True -> [0, 0]
        )

    lines_to_display = lines
        |> Enum.zip(Range.new(0, Enum.count(lines) - 1))
        |> Enum.slice(lines_with_error)

    lines_to_display
        |> Enum.map(lambda item_n_index:
            item = elem(item_n_index, 0)
            index = elem(item_n_index, 1)

            arrows = case index in lines_with_error:
                True ->
                    col_start = col_range_per_line |> Enum.at(index) |> Enum.at(0)
                    col_end = col_range_per_line |> Enum.at(index) |> Enum.at(0)

                    arrows = String.duplicate('^', String.length(text) - 1)
                    empty = String.duplicate(' ', String.length(text) - 1)

                    start = String.slice(empty, Range.new(0, col_start))
                    middle = String.slice(arrows, Range.new(col_start, col_end))
                    end = String.slice(empty, Range.new(col_end, String.length(text) - 1))

                    Enum.join([start, middle, end])
                False -> ''

            [item, arrows]
        )
        |> List.flatten()
        |> Enum.join('\n')
