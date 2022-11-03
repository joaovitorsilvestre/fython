def run(node, filename):
    state = {"node_count": 0, "refs_per_line": {}}

    [node, state] = add_statements_refs(node, state)

    sem = inject_into_node_quoted_function(
        node,
        generate_code_refs(state['refs_per_line'], filename)
    )
    node

def iterate_items(nodes, state):
    acc = {"nodes": [], "state": state}
    acc = Elixir.Enum.reduce(nodes, acc, lambda x, acc:
        [x, state] = add_statements_refs(x, acc['state'])
        {"nodes": Elixir.Enum.concat(acc['nodes'], [x]), "state": state}
    )
    [acc['nodes'], acc['state']]
    [nodes, state]


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
    case Elixir.Enum.member?(Core.Parser.Utils.nodes_types(), nodetype):
        False -> [(nodetype, meta, body), state]
        True ->
            [body, state] = case:
                Elixir.Enumerable.impl_for(body)    -> iterate_items(body, state)
                True                                -> add_statements_refs(body, state)
                True -> [body, state]

            [meta, state] = increase_node_count(meta, state)
            [(nodetype, meta, body), state]

def add_statements_refs(body, state):
    [body, state] = case:
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



def inject_into_node_quoted_function((:statements, meta, body), function_quoted):
    (:statements, meta, Elixir.Enum.concat(body, [function_quoted]))


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
