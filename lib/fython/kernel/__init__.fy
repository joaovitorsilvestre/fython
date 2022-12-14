exception SyntaxError:
    message = "Invalid syntax"
    position = None # (line, col_start, col_end)
    source_code = None

exception ArithmeticError:
    message = None

exception FunctionClauseError:
    # Raised when a function is called with invalid arguments
    # Example of when it will be raised:
    #   [1, 2, 3] |> Elixir.Enum.map(lambda (a, b): 1)
    #   the arity of the lambda is correct, but the pattern matching will fail

    message = None
    module = None
    function = None
    arity = None
    arguments = None
