def to_fython_exception(error <- Elixir.FunctionClauseError(), stacktrace):
    (_module, _function, arguments, _) = Elixir.Enum.at(stacktrace, 0)

    error = Exception.FunctionClauseError(
        message="",
        module=error.module,
        function=error.function,
        arity=error.arity,
        arguments=arguments,
    )

    to_fython_exception(error, stacktrace)


def to_fython_exception(error <- Elixir.ArithmeticError(), stacktrace):
    to_fython_exception(Exception.ArithmeticError(message=error.message), stacktrace)


def to_fython_exception(error, stacktrace):
    # If this functions has a error, it will create a infinite loop
    error_name = Elixir.Atom.to_string(error.__struct__)

    case Elixir.String.starts_with?(error_name, 'Elixir.Fython.'):
        True ->
            error # already a fython exception
        False ->
            # We cant raise a error here, otherwise it will enter in a infinite loop
            Elixir.IO.puts("This error doesnt has a conversor to fython yet")
            Elixir.IO.inspect(error)
            Elixir.IO.puts("that was the error stacktrace: ")
            Elixir.IO.inspect(stacktrace)
            Core.exit_with_status_code(0)

