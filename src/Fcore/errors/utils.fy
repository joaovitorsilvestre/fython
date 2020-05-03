def print_error(module_name, state, text):
    # support to show errors of lexer and parser

    guide = string_with_arrows(state, text)

    Enum.join([
        'File: ', module_name,
        ', line: ',
        (Map.get(state, "error") |> Map.get('pos_start') |> Map.get('ln')) + 1,
        '\n\n', guide, '\n\n',
        Map.get(state, "error") |> Map.get('msg')
    ])
        |> IO.puts()

def string_with_arrows(state, text):
    error = Map.get(state, "error")
    pos_start = Map.get(error, 'pos_start')
    pos_end = Map.get(error, 'pos_end')

    # number of lines that we will show above the first line with error
    # and number of lines that we will show bellow the last line with error
    num_show_above = 2
    num_show_bellow = 0

    lines = String.split(text, '\n')

    lines_with_error = Range.new(pos_start |> Map.get('ln'), pos_end |> Map.get('ln'))

    col_range_per_line = Range.new(0, Enum.count(lines))
        |> Enum.map(lambda ln:
            case:
                ln in lines_with_error ->
                    case:
                        ln == 0 ->
                            [Map.get(pos_start, 'col'), String.length(Enum.at(lines, 0))]
                        ln == Enum.at(lines_with_error, -1) ->
                            [
                                0 if Enum.count(lines_with_error) > 1 else Map.get(pos_start, 'col'),
                                Map.get(pos_end, 'col')
                            ]
                        True -> [0, String.length(Enum.at(lines, 0))]
                True -> [None, None]
        )

    lines_to_display = lines
        |> Enum.zip(Range.new(0, Enum.count(lines)))
        |> Enum.slice(Range.new(
            max(0, Enum.at(lines_with_error, 0) - num_show_above),
            Enum.at(lines_with_error, -1) + num_show_bellow
        ))

    lines_to_display
        |> Enum.map(lambda item_n_index:
            item = elem(item_n_index, 0)
            index = elem(item_n_index, 1)

            arrows = case index in lines_with_error:
                True ->
                    col_start = col_range_per_line |> Enum.at(index) |> Enum.at(0)
                    col_end = col_range_per_line |> Enum.at(index) |> Enum.at(1)

                    arrows = String.duplicate('^', String.length(text))
                    empty = String.duplicate(' ', String.length(text))

                    start = String.slice(empty, Range.new(0, col_start))
                    middle = String.slice(arrows, Range.new(col_start, col_end))
                    end = String.slice(empty, Range.new(col_end, String.length(text)))

                    Enum.join([start, middle, end])
                False -> ''

            [item, index, arrows]
        )
        |> Enum.map(lambda item_index_arrows:
            item = Enum.at(item_index_arrows, 0)
            index = Enum.at(item_index_arrows, 1)
            arrows = Enum.at(item_index_arrows, 2)

            prefix = Enum.count(Integer.digits(Map.get(pos_end, 'ln')))

            # num_line = Enum.join([index + 1, " "])
            num_line = IO.ANSI.format([
                :bright, :black, to_string(index + 1),
                String.duplicate(' ', (prefix - Enum.count(Integer.digits(index))) + 1)
            ])

            item = Enum.join([num_line, item])

            arrows = Enum.join([
                String.duplicate(' ', prefix),
                arrows
            ])

            [item, arrows]
        )
        |> List.flatten()
        |> Enum.filter(lambda i: String.trim(i) != '' if is_bitstring(i) else True)
        |> Enum.join('\n')
