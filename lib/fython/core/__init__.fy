def eval_string(string):
    eval_string(string, {"file": 'nofile', 'env': [], 'module_name': 'Nomodule'})

def eval_string(string, config <- {"file": file, "env": env, 'module_name': module_name}):
    (state, [(_, converted, _)]) = Core.Code.lexer_parse_convert_file(module_name, string, config)

    Elixir.Code.eval_quoted(converted, env, [])

def apply(function_name, args) if Elixir.Kernel.is_bitstring(function_name):
    function_name
        |> Elixir.String.to_atom()
        |> Elixir.Kernel.apply(args)

def apply(module_name, function_name, args) if Elixir.Kernel.is_bitstring(module_name) and Elixir.Kernel.is_bitstring(function_name):
    module_name = module_name |> Elixir.String.to_atom()
    function_name = function_name |> Elixir.String.to_atom()
    Elixir.Kernel.apply(module_name, function_name, args)

def apply(module_name, function_name, args) if Elixir.Kernel.is_atom(module_name) and Elixir.Kernel.is_atom(function_name):
    Elixir.Kernel.apply(module_name, function_name, args)

def exit_with_status_code(status):
    Erlang.init.stop(status)

def print(value) if Elixir.Kernel.is_bitstring(value):
    Elixir.IO.puts(value)

def print(value):
    value |> Elixir.Kernel.inspect() |> Elixir.IO.puts()

# sum
# TODO remove in the next release
def sum(left, right) if Elixir.Kernel.is_number(left) and Elixir.Kernel.is_number(right):
    Core.apply(:"erlang", :"+", [left, right])

def sum(left, right) if Elixir.Kernel.is_bitstring(left) and Elixir.Kernel.is_bitstring(right):
    # TODO find a way to use erlang
    Elixir.Enum.join([left, right])

def sum(left, right) if Elixir.Kernel.is_list(left) and Elixir.Kernel.is_list(right):
    Core.apply(:"erlang", :"++", [left, right])


# len

def len(value) if Elixir.Kernel.is_list(value) or Elixir.Kernel.is_map(value):
    Elixir.Enum.count(value)

def len(value) if Elixir.Kernel.is_bitstring(value):
    Elixir.String.length(value)

# enumerate

def enumerate(value) if Elixir.Kernel.is_list(value):
    value |> reverse_with_index()

def enumerate(value <- Elixir.Stream()):
    value |> reverse_with_index()

def enumerate(value <- Elixir.Range()):
    value |> reverse_with_index()

def enumerate(value) if Elixir.Kernel.is_map(value):
    value |> Elixir.Map.keys() |> reverse_with_index()

defp reverse_with_index(enum):
    enum
        |> Elixir.Stream.with_index()
        |> Elixir.Stream.map(lambda (item, index): (index, item))
