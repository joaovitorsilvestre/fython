def run(node, init_state, callback_each_node):
    # callback_each_node must be a function that returns [node, state]
    state = Elixir.Map.put(init_state, "callback", callback_each_node)
    [node, state] = enter_node(node, state)


def iterate_items(nodes, state):
    acc = {"nodes": [], "state": state}
    acc = Elixir.Enum.reduce(nodes, acc, lambda x, acc:
        [x, state] = enter_node(x, acc['state'])
        {"nodes": Elixir.Enum.concat(acc['nodes'], [x]), "state": state}
    )
    [acc['nodes'], acc['state']]


def enter_node((left, right), state):
    [left, state] = enter_node(left, state)
    [right, state] = enter_node(right, state)
    [(left, right), state]

def enter_node([node], state):
    [node, state] = enter_node(node, state)
    [[node], state]

def enter_node(False, state):
    [False, state]

def enter_node(True, state):
    [True, state]

def enter_node(None, state):
    [None, state]

def enter_node((nodetype, meta, body), state):
    case Elixir.Enum.member?(Core.Parser.Utils.nodes_types(), nodetype):
        False -> [(nodetype, meta, body), state]
        True ->
            [body, state] = case:
                Elixir.Enumerable.impl_for(body)    -> iterate_items(body, state)
                True                                -> enter_node(body, state)
                True -> [body, state]

            callback = state['callback']
            [(nodetype, meta, body), state] = callback((nodetype, meta, body), state)
            [(nodetype, meta, body), state]

def enter_node(body, state):
    [body, state] = case:
        body == True                        -> [body, state]
        body == False                       -> [body, state]
        body == None                        -> [body, state]
        body == []                          -> [body, state]
        Elixir.Kernel.is_binary(body)       -> [body, state]
        Elixir.Kernel.is_atom(body)         -> [body, state]
        Elixir.Kernel.is_number(body)       -> [body, state]
        Elixir.Enumerable.impl_for(body)    -> iterate_items(body, state)
        True                                -> raise "Missing treat this case"

    [body, state]

def increase_node_count(meta, state <- {"node_count": node_count}):
    meta = Elixir.Map.put(meta, "ref_line", node_count)

    meta_per_line_ref = case Elixir.Map.has_key?(state['meta_per_line_ref'], meta['ref_line']):
        True ->
            raise "node_count already present in 'meta_per_line_ref', theres a error in this pos"
        False ->
            Elixir.Map.put(
                state['meta_per_line_ref'], node_count, Elixir.Map.delete(meta, 'node_count')
            )

    state = state
        |> Elixir.Map.put("node_count", node_count + 1)
        |> Elixir.Map.put("meta_per_line_ref", meta_per_line_ref)

    [meta, state]