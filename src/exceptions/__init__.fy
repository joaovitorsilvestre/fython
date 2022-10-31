def format_traceback(error, stacktrace):
    formated = stacktrace
        |> Elixir.Enum.filter(&is_fython_stack/1)
        |> Elixir.Enum.reverse()
        |> Elixir.Enum.map(&format_line_stacktrace/1)
        |> Elixir.Enum.join("")

    Elixir.IO.puts("Traceback (most recent call last):")
    Elixir.IO.puts(formated)
    Elixir.IO.inspect(error)

def format_line_stacktrace((module, func_name, _, [(:file, file), (:line, line)])):
    Elixir.Enum.join(["  file: ", file, ", line: ", line, "\n", "    ",  module, ".", func_name, "\n"], "")

def is_fython_stack(stack):
    module = stack |> Elixir.Kernel.elem(0)
    Elixir.Atom.to_string(module) |> Elixir.String.starts_with?("Fython.")
