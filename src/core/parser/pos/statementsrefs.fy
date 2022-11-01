def run(node, filename):
    # TODO examplain why this module exists and its job
    state = {
        "node_count": 0,
        "refs_per_line": {}
    }
    [node, state] = add_statements_refs(node, state)

    com = inject_into_node_quoted_function(
        node,
        generate_code_refs(state['refs_per_line'], filename),
    )
    Elixir.IO.inspect(com)
    com

def iterate_items(nodes, state):
    acc = {"nodes": [], "state": state}
    acc = Elixir.Enum.reduce(nodes, acc, lambda x, acc:
        [x, state] = add_statements_refs(x, acc['state'])
        {"nodes": Elixir.Enum.concat(acc['nodes'], [x]), "state": state}
    )
    [acc['nodes'], acc['state']]


def add_statements_refs((nodetype, meta, body), state):
    [meta, state] = increase_node_count(meta, state)

    [body, state] = case:
        Elixir.Enumerable.impl_for(body) -> iterate_items(body, state)
        True ->
            [meta, state] = increase_node_count(meta, state)
            [body, state]

    [(nodetype, meta, body), state]


def add_statements_refs((left, right), state):
    [left, state] = add_statements_refs(left, state)
    [right, state] = add_statements_refs(right, state)
    [(left, right), state]

def add_statements_refs([node], state):
    [node, state] = add_statements_refs(node, state)
    [[node], state]

def add_statements_refs(node, state):
    case:
        node == True                        -> [node, state]
        node == True                        -> [node, state]
        node == False                       -> [node, state]
        node == None                        -> [node, state]
        node == []                          -> [node, state]
        Elixir.Kernel.is_binary(node)       -> [node, state]
        Elixir.Kernel.is_atom(node)         -> [node, state]
        Elixir.Kernel.is_number(node)       -> [node, state]
        Elixir.Enumerable.impl_for(node)    -> iterate_items(node, state)
        True                                -> raise "Should not get here"

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


def inject_into_node_quoted_function((:statements, meta, body), function_quoted):
    (:statements, meta, [*body, function_quoted])


def generate_code_refs(refs, filename):
    # return quoted verson of the folowing code:
    # def __fython_get_node_ref__(key):
    #     refs = {1: (0, 0, 0)}
    #     Elixir.Map.get(regs, key)

    meta = {
        "node_count": 0,
        "start": (0, 0, 0),
        "end": (0, 0, 0),
        "file": filename,
    }

    (
        :def,
        Elixir.Map.put(meta, "docstring", None),
        [
            "__fython_get_node_ref__",
            [
                (:var, meta, [False, "key"])
            ],
            (
                :statements,
                meta,
                [
                    (
                        :pattern,
                        meta,
                        [
                            (:var, meta, [False, "refs"]),
                            (
                                :map,
                                meta,
                                [
                                    ((:number, meta, [1]), (:number, meta, [10]))
                                ]
                            )
                        ]
                    ),
                    (
                        :call,
                        meta,
                        [
                            (:var, meta, [False, "Elixir.Map.get"]),
                            [
                                (:var, meta, [False, "refs"]),
                                (:var, meta, [False, "key"])
                            ],
                            [],
                            False
                        ]
                    )
                ]
            )
        ]
    )
