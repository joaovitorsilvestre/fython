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


def format_traceback(error <- Exception.FunctionClauseError(), stacktrace):
    only_fython_stacktrace = stacktrace
        |> Elixir.Enum.filter(&is_fython_stack?/1)

    formated_lines = only_fython_stacktrace
        |> Elixir.Enum.reverse()
        |> Elixir.Enum.slice(0..-2) # dont show last line stack because it will appear in source code pointers
        |> Elixir.Enum.map(&format_line_stacktrace/1)
        |> Elixir.Enum.join("")

    source_code_error_pointing = only_fython_stacktrace
        |> Elixir.Enum.at(0)
        |> gen_source_code_error_pointing()

    Elixir.IO.puts("Traceback (most recent call last):")
    Elixir.IO.puts(formated_lines)
    Elixir.IO.puts(source_code_error_pointing)

    arguments = error.arguments
        |> Elixir.Enum.with_index()
        |> Elixir.Enum.reduce("", lambda (arg, index), acc:
            arg_number = case index:
                0 -> "1st"
                1 -> "2nd"
                2 -> "3rd"
                _ -> Elixir.Enum.join([index + 1, "th"])

            Elixir.Enum.join([acc, "        * ",arg_number, " argument: ", Elixir.Kernel.inspect(arg), "\n"])
        )

    Elixir.IO.puts(Elixir.Enum.join([
        "    function received the arguments: \n", arguments, "\n",
        "    Maybe theres is a pattern that didn't match with the arguments?\n"
    ]))
    display_error_name_formated(error)


def format_traceback(error <- Exception.SyntaxError(), stacktrace):
    only_fython_stacktrace = stacktrace
        |> Elixir.Enum.filter(&is_fython_stack?/1)

    (line, col_start, col_end) = error.position

    meta = {
        "start": (None, line, col_start),
        "end": (None, line, col_end)
    }

    source_code_error_pointing = Exception.Code.format_error_in_source_code(
        error.source_code, meta
    )

    Elixir.IO.puts(source_code_error_pointing)
    display_error_name_formated(error)


def format_traceback(error, stacktrace):
    # Main function to format stacktrace
    only_fython_stacktrace = stacktrace
        |> Elixir.Enum.filter(&is_fython_stack?/1)

    formated_lines = only_fython_stacktrace
        |> Elixir.Enum.reverse()
        |> Elixir.Enum.map(&format_line_stacktrace/1)
        |> Elixir.Enum.join("\n")

    source_code_error_pointing = only_fython_stacktrace
        |> Elixir.Enum.at(0)
        |> gen_source_code_error_pointing()

    Elixir.IO.puts("Traceback (most recent call last):")
    Elixir.IO.puts(formated_lines)
    Elixir.IO.puts(source_code_error_pointing)
    display_error_name_formated(error)


def display_error_name_formated(error):
    error_name = module_name_as_string(error.__struct__)
    Elixir.IO.puts(error_name)
    Elixir.IO.puts(Elixir.Enum.join(["    ", error.message]))


def module_name_as_string(module):
    # Return the name of te Module as string
    # and also without the Fython prefix
    module = case Elixir.Kernel.is_atom(module):
        True -> Elixir.Atom.to_string(module)
        False -> module

    module |> Elixir.String.replace_prefix("Elixir.Fython.", "")


def format_line_stacktrace((module, func_name, _, [(:file, file), (:line, line)])):
    format_line_stacktrace((module, func_name, None, [(:file, file), (:line, line), (:error_info, None)]))


def format_line_stacktrace((module, func_name, _, [(:file, file), (:line, line), (:error_info, _error_info)])):
    module = module_name_as_string(module)
    meta = get_meta_of_line_ref(module, line)
    line = get_real_line_of_the_error(module, line)
    source_code = get_module_source_code(module)

    first_line = ["  file: ", file, ", line: ", line, " at ",  module, ".", func_name, "()\n"]

    second_line = Exception.Code.format_error_in_source_code(source_code, meta, 0, "    ")

    Elixir.Enum.join([*first_line, second_line, "\n"])

def format_line_stacktrace(aaa):
    Elixir.IO.puts('wtffffffff')
    Elixir.IO.inspect(aaa)
    "Not hable to parse"

def gen_source_code_error_pointing((module, func_name, _, [(:file, file), (:line, line)])):
    gen_source_code_error_pointing((module, func_name, None, [(:file, file), (:line, line), (:error_info, None)]))


def gen_source_code_error_pointing((module, func_name, _, [(:file, file), (:line, line), (:error_info, _error_info)])):
    module = module_name_as_string(module)

    source_code = get_module_source_code(module)
    meta = get_meta_of_line_ref(module, line)
    Exception.Code.format_error_in_source_code(source_code, meta)


def get_module_source_code(module):
    # Use Metadata functions saved in module to retrieve the source code of the module
    Core.apply(module, '__fython_get_file_source_code__', [])


def get_meta_of_line_ref(module, line):
    # Returns the meta of the node in the line
    Core.apply(module, '__fython_get_node_ref__', [line])


def get_real_line_of_the_error(module, line):
    # Gets the real line of the node that originated the error
    {"start": (_, real_line, _)} = get_meta_of_line_ref(module, line)
    real_line + 1


def is_fython_stack?(stack):
    # Informs if this stack is from code written in Fython
    # Returning False if it is from Elixir or Erlang
    module = stack |> Elixir.Kernel.elem(0)
    Elixir.Atom.to_string(module) |> Elixir.String.starts_with?("Fython.")


def is_elixir_error?(error):
    # Informs if this error is from Elixir
    module = error.__struct__
    Elixir.Atom.to_string(module) |> Elixir.String.starts_with?("Elixir.")

