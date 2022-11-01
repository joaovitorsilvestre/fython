def add_statements_refs(node):
    # TODO examplain why this module exists and its job
    state = {
        "node_count": 0,
        "refs_per_line": {}
    }
    [node, state] = add_statements_refs(node, state)

#    inject_into_node_quoted_function(
#        node,
#        generate_code_refs(state['refs_per_line'])
#    )
    node

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
    body = Elixir.Enum.concat(body, [function_quoted])
    r = (:statements, meta, body)


#def generate_code_refs(refs):
#    code = [
#        "def __fython_get_node_ref__(key):",
#        "   ref = {1: 10}",
#        "   Elixir.Map.get(ref, key)",
#    ]
#    code = "def __fython_get_node_ref__(key):\n    ref = {1: 10}\n    Elixir.Map.get(ref, ref)"
#
#    code
##        |> Elixir.Enum.join("\n")
#        |> Core.Code.quote_fython([(:skip_pos_parser, True)])

def generate_code_refs(refs):
    # return quoted verson of the folowing code:
    # def __fython_get_node_ref__(key):
    #     refs = {1: (0, 0, 0)}
    #     Elixir.Map.get(regs, key)

    meta = {
        "node_count": 0
    }

#    keys_quoted = refs
#        |> Elixir.Map.keys()
#        |> Elixir.Enum.map(lambda x: (:number, meta, [x]))
#
#    values_quoted = refs
#        |> Elixir.Map.values()
#        |> Elixir.Enum.map(
#            lambda x:
#                (:tuple, meta, [69]) # TODO
#        )
#
#    refs_quoted = Elixir.Enum.zip(keys_quoted, values_quoted)
#        |> Elixir.Enum.flat_map(lambda (a, b): [a, b])
#
#    Elixir.IO.inspect('refs quoted')
#    Elixir.IO.inspect(refs_quoted)

    (
        :def,
        meta,
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
