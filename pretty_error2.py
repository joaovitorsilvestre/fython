source_code = """def run():
    segunda()

def segunda():
    da_erro(True)

def da_erro(a):
    b = 0

    case a:
        False -> None
        10 -> None
        True -> 10 / b
"""

meta = {"start": (16, 12, 16), "end": (22, 12, 22)}

state = {
    "source_code": source_code,
    "source_code_lines": source_code.split('\n'),
    "source_code_lines_indexed": list(enumerate(source_code.split('\n'))),
    "line_num": meta['start'][1],  # line starting at 0
    "start": (meta['start'][1], meta['start'][2]),
    "end": (meta['end'][1], meta['end'][2]),
}


def get_lines_above(state):
    HOW_MANY_LINES_SHOW_ABOVE = 5

    source_code_lines = [(num, line) for num, line in enumerate(state['source_code_lines'])]

    if state['line_num'] > HOW_MANY_LINES_SHOW_ABOVE:
        lines_to_keep_above = source_code_lines[slice(state['line_num']-HOW_MANY_LINES_SHOW_ABOVE, state['line_num'])]
    else:
        lines_to_keep_above = source_code_lines[0:state['line_num']]

    return lines_to_keep_above


def draw_pointers(state):
    start, end = state['start'][1], state['end'][1]

    pointer = " " * (get_need_size_numbers(state) + 3)
    for i in range(0, start):
        pointer += '~'

    for i in range(start, end):
        pointer += "^"
    return [pointer]


def get_lines_to_print(state):
    lines_above = get_lines_above(state)
    current_line = state['source_code_lines_indexed'][state['line_num']]
    pointers = draw_pointers(state)

    return [
        *add_line_numbers(meta, lines_above),
        *add_line_numbers(meta, [current_line]),
        *pointers,
    ]


def get_need_size_numbers(state):
    return len(str(state['end'][0]))


def add_line_numbers(meta, list_of_lines_indexed):
    size = get_need_size_numbers(meta)
    return [
        f"{str(i + 1).rjust(size)} ǁ {l}" for i, l in list_of_lines_indexed
    ]


def print_error(state):
    for line in get_lines_to_print(state):
        print(line)

print_error(state)