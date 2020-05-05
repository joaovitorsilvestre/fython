def convert_binop_node(value):
    not_case = lambda value:
        Enum.join([
            "{:__block__, [], [{:!, [context: Elixir, import: Kernel], [", value, "]}]}"
        ])

    plus_case = lambda value:
        Enum.join([
            "{:+, [context: Elixir, import: Kernel], [", value, "]}"
        ])

    minus_case = lambda value:
        Enum.join([
            "{:-, [context: Elixir, import: Kernel], [", value, "]}"
        ])

    case [False, True, True]:
        [True, _, _] -> not_case(value)
        [_, True, _] -> plus_case(value)
        [_, _, True] -> minus_case(value)