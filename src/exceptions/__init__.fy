def format_traceback(error, stacktrace):
    formated_lines = stacktrace
        |> Elixir.Enum.filter(&is_fython_stack/1)
        |> Elixir.Enum.reverse()
        |> Elixir.Enum.map(&format_line_stacktrace/1)
        |> Elixir.Enum.join("")

    code_with_error = source_code_with_error(Elixir.Enum.at(stacktrace, 0))

    Elixir.IO.puts("Traceback (most recent call last):")
    Elixir.IO.puts(formated_lines)
    Elixir.IO.puts(code_with_error)

def ensure_string_module_name(module):
    module
        |> Elixir.Atom.to_string()
        |> Elixir.String.replace_prefix("Fython.", "")

def get_module_source_code(module):
    module = ensure_string_module_name(module)
    code_to_run = Elixir.Enum.join([module, '.__fython_get_file_source_code__()'])
    (result, _) = Core.eval_string(code_to_run)
    result

def line_meta_of_line_of_module(module, line_ref):
    module = ensure_string_module_name(module)
    code_to_run = Elixir.Enum.join([module, '.__fython_get_node_ref__(', line_ref, ')'])
    (result, _) = Core.eval_string(code_to_run)

def format_line_stacktrace((module, func_name, _, [(:file, file), (:line, line)])):
    format_line_stacktrace((module, func_name, None, [(:file, file), (:line, line), (:error_info, None)]))

def format_line_stacktrace((module, func_name, _, [(:file, file), (:line, line), (:error_info, _error_info)])):
    module = ensure_string_module_name(module)

    Elixir.Enum.join(["  file: ", file, ", line: ", line, "\n", "    ",  module, ".", func_name, "\n"], "")

def source_code_with_error((module, func_name, _, [(:file, file), (:line, line)])):
    source_code_with_error((module, func_name, None, [(:file, file), (:line, line), (:error_info, None)]))

def source_code_with_error((module, func_name, _, [(:file, file), (:line, line), (:error_info, _error_info)])):
    source_code = get_module_source_code(module)

    Elixir.IO.inspect(line_meta_of_line_of_module(module, line))

    source_code

def is_fython_stack(stack):
    module = stack |> Elixir.Kernel.elem(0)
    Elixir.Atom.to_string(module) |> Elixir.String.starts_with?("Fython.")
