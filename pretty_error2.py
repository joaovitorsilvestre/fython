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
    "position": (meta['start'][1], meta['start'][2], meta['end'][2]),  # line starting at 0
}


def get_lines_above(state):
    line_num = state['position'][0]
    HOW_MANY_LINES_SHOW_ABOVE = 5

    source_code_lines = [(num, line) for num, line in enumerate(state['source_code_lines'])]

    if line_num > HOW_MANY_LINES_SHOW_ABOVE:
        lines_to_keep_above = source_code_lines[slice(line_num-HOW_MANY_LINES_SHOW_ABOVE, line_num)]
    else:
        lines_to_keep_above = source_code_lines[0:line_num]

    return lines_to_keep_above


def draw_pointers(state):
    start, end = state['position'][1], state['position'][2]

    pointer = " " * (get_necessary_size_to_fit_line_numbers(state) + 3)
    for i in range(0, start):
        pointer += '~'

    for i in range(start, end):
        pointer += "^"
    return [pointer]


def get_lines_to_print(state):
    lines_above = get_lines_above(state)
    current_line = state['source_code_lines_indexed'][state['position'][0]]
    pointers = draw_pointers(state)

    return [
        *add_line_numbers(state, lines_above),
        *add_line_numbers(state, [current_line]),
        *pointers,
    ]


def get_necessary_size_to_fit_line_numbers(state):
    return len(str(state['position'][2]))


def add_line_numbers(state, list_of_lines_indexed):
    size = get_necessary_size_to_fit_line_numbers(state)
    return [
        f"{str(i + 1).rjust(size)} ǁ {l}" for i, l in list_of_lines_indexed
    ]


def print_error(state):
    for line in get_lines_to_print(state):
        print(line)

print_error(state)