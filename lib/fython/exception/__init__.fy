def format_traceback(error, stacktrace):
    # Main function to format stacktrace


    only_fython_stacktrace = stacktrace
        |> Elixir.Enum.filter(&is_fython_stack?/1)

    formated_lines = only_fython_stacktrace
        |> Elixir.Enum.reverse()
        |> Elixir.Enum.map(&format_line_stacktrace/1)
        |> Elixir.Enum.join("")

    source_code_error_pointing = only_fython_stacktrace
        |> Elixir.Enum.at(0)
        |> gen_source_code_error_pointing()

    Elixir.IO.puts("Traceback (most recent call last):")
    Elixir.IO.puts(formated_lines)
    Elixir.IO.puts(source_code_error_pointing)
    display_error_formated(error)

def display_error_formated(error):
    error_name = module_name_as_string(error.__struct__)
    Elixir.IO.puts(error_name)
    Elixir.IO.puts(Elixir.Enum.join(["    ", error.message]))

def module_name_as_string(module):
    # Return the name of te Module as string
    # and also without the Fython prefix
    module = case Elixir.Kernel.is_atom(module):
        True -> Elixir.Atom.to_string(module)
        False -> module

    module |> Elixir.String.replace_prefix("Fython.", "")

def format_line_stacktrace((module, func_name, _, [(:file, file), (:line, line)])):
    format_line_stacktrace((module, func_name, None, [(:file, file), (:line, line), (:error_info, None)]))

def format_line_stacktrace((module, func_name, _, [(:file, file), (:line, line), (:error_info, _error_info)])):
    module = module_name_as_string(module)
    line = get_real_line_of_the_error(module, line)

    Elixir.Enum.join(["  file: ", file, ", line: ", line, "\n", "    -> ",  module, ".", func_name, "()\n"], "")

def gen_source_code_error_pointing((module, func_name, _, [(:file, file), (:line, line)])):
    gen_source_code_error_pointing((module, func_name, None, [(:file, file), (:line, line), (:error_info, None)]))

def gen_source_code_error_pointing((module, func_name, _, [(:file, file), (:line, line), (:error_info, _error_info)])):
    module = module_name_as_string(module)

    source_code = get_module_source_code(module)
    meta = get_meta_of_line_ref(module, line)
    Exception.Code.format_error_in_source_code(source_code, meta)

def gen_source_code_error_pointing(maoi):
    Elixir.IO.inspect(maoi)
    raise 'wtf'

def get_module_source_code(module):
    # Use Metadata functions saved in module to retrieve the source code of the module
    code_to_run = Elixir.Enum.join([module, '.__fython_get_file_source_code__()'])
    (result, _) = Core.eval_string(code_to_run)
    result

def get_meta_of_line_ref(module, line):
    # Returns the meta of the node in the line
    code_to_run = Elixir.Enum.join([module, '.__fython_get_node_ref__(', line, ')'])
    (result, _) = Core.eval_string(code_to_run)
    result

def get_real_line_of_the_error(module, line):
    # Gets the real line of the node that originated the error
    {"start": (_, real_line, _)} = get_meta_of_line_ref(module, line)
    real_line + 1

def is_fython_stack?(stack):
    # Informs if this stack is from code written in Fython
    # Returning False if it is from Elixir or Erlang
    module = stack |> Elixir.Kernel.elem(0)
    Elixir.Atom.to_string(module) |> Elixir.String.starts_with?("Fython.")
