def print_error(module_name, state, text):
    # support to show errors of lexer and parser

    guide = string_with_arrows(state, text)

    Elixir.Enum.join([
        'File: ', module_name,
        ', line: ',
        (Elixir.Map.get(state, "error") |> Elixir.Map.get('pos_start') |> Elixir.Map.get('ln')) + 1,
        '\n\n', guide, '\n\n',
        Elixir.Map.get(state, "error") |> Elixir.Map.get('msg')
    ])
        |> Elixir.IO.puts()

def string_with_arrows(state, text):
    error = Elixir.Map.get(state, "error")
    pos_start = Elixir.Map.get(error, 'pos_start')
    pos_end = Elixir.Map.get(error, 'pos_end')

    # number of lines that we will show above the first line with error
    # and number of lines that we will show bellow the last line with error
    num_show_above = 2
    num_show_bellow = 0

    lines = Elixir.String.split(text, '\n')

    lines_with_error = Range.new(pos_start |> Elixir.Map.get('ln'), pos_end |> Elixir.Map.get('ln'))

    col_range_per_line = Range.new(0, Elixir.Enum.count(lines))
        |> Elixir.Enum.map(lambda ln:
            case:
                ln in lines_with_error ->
                    case:
                        ln == 0 ->
                            [Elixir.Map.get(pos_start, 'col'), Elixir.String.length(Elixir.Enum.at(lines, 0))]
                        ln == Elixir.Enum.at(lines_with_error, -1) ->
                            [
                                0 if Elixir.Enum.count(lines_with_error) > 1 else Elixir.Map.get(pos_start, 'col'),
                                Elixir.Map.get(pos_end, 'col')
                            ]
                        True -> [0, Elixir.String.length(Elixir.Enum.at(lines, 0))]
                True -> [None, None]
        )

    lines_to_display = lines
        |> Elixir.Enum.zip(Range.new(0, Elixir.Enum.count(lines)))
        |> Elixir.Enum.slice(Range.new(
            max(0, Elixir.Enum.at(lines_with_error, 0) - num_show_above),
            Elixir.Enum.at(lines_with_error, -1) + num_show_bellow
        ))

    lines_to_display
        |> Elixir.Enum.map(lambda item_n_index:
            item = Elixir.Kernel.elem(item_n_index, 0)
            index = Elixir.Kernel.elem(item_n_index, 1)

            arrows = case index in lines_with_error:
                True ->
                    col_start = col_range_per_line |> Elixir.Enum.at(index) |> Elixir.Enum.at(0)
                    col_end = col_range_per_line |> Elixir.Enum.at(index) |> Elixir.Enum.at(1)

                    arrows = Elixir.String.duplicate('^', Elixir.String.length(text))
                    empty = Elixir.String.duplicate(' ', Elixir.String.length(text))

                    start = Elixir.String.slice(empty, Range.new(0, col_start))
                    middle = Elixir.String.slice(arrows, Range.new(col_start, col_end))
                    _end = Elixir.String.slice(empty, Range.new(col_end, Elixir.String.length(text)))

                    Elixir.Enum.join([start, middle, _end])
                False -> ''

            [item, index, arrows]
        )
        |> Elixir.Enum.map(lambda item_index_arrows:
            item = Elixir.Enum.at(item_index_arrows, 0)
            index = Elixir.Enum.at(item_index_arrows, 1)
            arrows = Elixir.Enum.at(item_index_arrows, 2)

            prefix = Elixir.Enum.count(Integer.digits(Elixir.Map.get(pos_end, 'ln')))

            # num_line = Elixir.Enum.join([index + 1, " "])
            num_line = Elixir.IO.ANSI.format([
                :bright, :black, Elixir.Kernel.to_string(index + 1),
                Elixir.String.duplicate(' ', (prefix - Elixir.Enum.count(Integer.digits(index))) + 1)
            ])

            item = Elixir.Enum.join([num_line, item])

            arrows = Elixir.Enum.join([
                Elixir.String.duplicate(' ', prefix),
                arrows
            ])

            [item, arrows]
        )
        |> Elixir.List.flatten()
        |> Elixir.Enum.filter(lambda i: Elixir.String.trim(i) != '' if Elixir.Kernel.is_bitstring(i) else True)
        |> Elixir.Enum.join('\n')
