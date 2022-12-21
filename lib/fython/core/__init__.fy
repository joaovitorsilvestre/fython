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

def sum(a, b) if Elixir.Kernel.is_number(a) and Elixir.Kernel.is_number(b):
    Core.apply(:"erlang", :"+", [a, b])

def sum(a, b) if Elixir.Kernel.is_bitstring(a) and Elixir.Kernel.is_bitstring(b):
    # TODO find a way to use erlang
    Elixir.Enum.join([a, b])

def sum(a, b) if Elixir.Kernel.is_list(a) and Elixir.Kernel.is_list(b):
    Core.apply(:"erlang", :"++", [a, b])

# len

def len(value) if Elixir.Kernel.is_list(value) or Elixir.Kernel.is_map(value):
    Elixir.Enum.count(value)

def len(value) if Elixir.Kernel.is_bitstring(value):
    Elixir.String.length(value)

def len(value) if Elixir.Kernel.is_tuple(value):
    Elixir.Kernel.tuple_size(value)

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
