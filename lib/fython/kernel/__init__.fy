exception SyntaxError:
    message = "Invalid syntax"
    position = None # (line, col_start, col_end)
    source_code = None

exception ArithmeticError:
    message = None
