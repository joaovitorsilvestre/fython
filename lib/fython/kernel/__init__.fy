exception SyntaxError:
    message = "Invalid syntax"
    position = None # (line, col_start, col_end)
    source_code = None

exception ArithmeticError:
    message = None

def global_error_handling(error, stacktrace):
    # Stops the aplication with code 1
    stop_vm_with_code(1)

def stop_vm_with_code(code):
    Erlang.init.stop(code)
