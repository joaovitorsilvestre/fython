def run(node):
    state = {"node_count": 0, "refs_per_line": {}}
    [node, state] = add_statements_refs(node, state)
    node

def iterate_items(nodes, state):
    acc = {"nodes": [], "state": state}
    acc = Elixir.Enum.reduce(nodes, acc, lambda x, acc:
        [x, state] = add_statements_refs(x, acc['state'])
        {"nodes": Elixir.Enum.concat(acc['nodes'], [x]), "state": state}
    )
    [acc['nodes'], acc['state']]


def add_statements_refs((left, right), state):
    [left, state] = add_statements_refs(left, state)
    [right, state] = add_statements_refs(right, state)
    [(left, right), state]

def add_statements_refs([node], state):
    [node, state] = add_statements_refs(node, state)
    [[node], state]

def add_statements_refs(False, state):
    [False, state]

def add_statements_refs(True, state):
    [True, state]

def add_statements_refs(None, state):
    [None, state]

def add_statements_refs((nodetype, meta, body), state):
    [body, state] = case:
        Elixir.Enumerable.impl_for(body)    -> iterate_items(body, state)
        True                                -> add_statements_refs(body, state)

    [meta, state] = increase_node_count(meta, state)
    [(nodetype, meta, body), state]

def add_statements_refs(body, state):
    [body, state] = case:
        body == True                        -> [body, state]
        body == True                        -> [body, state]
        body == False                       -> [body, state]
        body == None                        -> [body, state]
        body == []                          -> [body, state]
        Elixir.Kernel.is_binary(body)       -> [body, state]
        Elixir.Kernel.is_atom(body)         -> [body, state]
        Elixir.Kernel.is_number(body)       -> [body, state]
        Elixir.Enumerable.impl_for(body)    -> iterate_items(body, state)
        True                                -> raise "faltou esse"

    [body, state]

def increase_node_count(meta, state <- {"node_count": node_count}):
    meta = Elixir.Map.put(meta, "node_count", node_count)

    refs_per_line = case Elixir.Map.has_key?(state['refs_per_line'], meta['node_count']):
        True ->
            raise "node_count already present in 'refs_per_line', theres a error in this pos"
        False ->
            state['refs_per_line']
                |> Elixir.Map.put(
                    node_count, Elixir.Map.delete(meta, 'node_count')
                )

    state = state
        |> Elixir.Map.put("node_count", node_count + 1)
        |> Elixir.Map.put("refs_per_line", refs_per_line)

    [meta, state]