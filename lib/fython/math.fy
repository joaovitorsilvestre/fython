def sum(left, right) if Elixir.Kernel.is_number(left) and Elixir.Kernel.is_number(right):
    Core.apply(:"erlang", :"+", [left, right])

def sum(left, right) if Elixir.Kernel.is_bitstring(left) and Elixir.Kernel.is_bitstring(right):
    # TODO find a way to use erlang
    Elixir.Enum.join([left, right])

def sum(left, right) if Elixir.Kernel.is_list(left) and Elixir.Kernel.is_list(right):
    Core.apply(:"erlang", :"++", [left, right])
