def add_prefix_to_function_calls(node, None):
    node

def add_prefix_to_function_calls(node, bootstrap_prefix):
    [node, state] = Core.Parser.Traverse.run(
        node, {"bootstrap_prefix": bootstrap_prefix}, &add_prefix/2
    )
    node

def add_prefix(node <- (:struct, meta, [struct_name, keywords]), state):
    {"bootstrap_prefix": bootstrap_prefix} = state

    struct_name = case Elixir.String.starts_with?(struct_name, 'Elixir.'):
        True -> struct_name
        False -> Elixir.Enum.join([bootstrap_prefix, '.', struct_name])

    [(:struct, meta, [struct_name, keywords]), state]

def add_prefix(node <- (:call, meta, [func_name, args, keywords, False]), state):
    {"bootstrap_prefix": bootstrap_prefix} = state

    (:var, var_meta, [var_pin, being_called]) = func_name

    being_called = case (Core.Parser.Utils.is_calling_function_of_fython_module(node), bootstrap_prefix):
        (False, _) -> being_called
        (True, '') -> being_called # no prefix
        (True, _) -> Elixir.Enum.join([bootstrap_prefix, '.', being_called])

    func_name = (:var, var_meta, [var_pin, being_called])

    [(:call, meta, [func_name, args, keywords, False]), state]

def add_prefix(node, state):
    [node, state]