def run(node, source_code):
    # It has the job of converting the line of each node to an id.
    # Elixir dont allow us to get more than the line number in __STACKTRACE__,
    # so we use the line of node as a key and store the meta that we want
    # in a function that we can call later with the line number and get the original meta

    state = {"node_count": 0, "meta_per_line_ref": {}}

    [node, state] = add_statements_refs(node, state)

    node
        |> inject_into_node_quoted_function(quoted_get_refs_func(state['meta_per_line_ref']))
        |> inject_into_node_quoted_function(quoted_source_code_func(source_code))

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



def inject_into_node_quoted_function((:statements, meta, body), function_quoted):
    (:statements, meta, Elixir.Enum.concat(body, [function_quoted]))

def quoted_get_refs_func(meta_per_line_ref):
    # return quoted verson of the folowing code:
    # def __fython_get_node_ref__(key):
    #     refs = {1: (0, 0, 0)}
    #     Elixir.Map.get(regs, key)

    # TODO retirar todo esse inline quoted e fazer uma
    # TODO string multilinha com o que queremos e rodar o nosso quote
    # TODO muito mais fácil de endenter e mais elegante

    meta = {
        "start": (0, 0, 0),
        "end": (0, 0, 0),
    }

    map_body_quoted = meta_per_line_ref
        |> Elixir.Enum.map(
            lambda (key, value):
                key_quoted = (:number, meta, [key])
                (s_idx, s_ln, s_col) = value['start']
                (e_idx, e_ln, e_col) = value['end']

                value_quoted = (
                    :map,
                    meta,
                    [
                        (
                            (:string, meta, ["start"]),
                            (
                                :tuple,
                                meta,
                                [
                                    (:number, meta, [s_idx]),
                                    (:number, meta, [s_ln]),
                                    (:number, meta, [s_col]),
                                ]
                            )
                        ),
                        (
                            (:string, meta, ["end"]),
                            (
                                :tuple,
                                meta,
                                [
                                    (:number, meta, [e_idx]),
                                    (:number, meta, [e_ln]),
                                    (:number, meta, [e_col]),
                                ]
                            )
                        ),
                    ]
                )

                (key_quoted, value_quoted)
        )

    (
        :def,
        Elixir.Map.put(meta, "docstring", None),
        [
            "__fython_get_node_ref__",
            [
                (:var, meta, [False, "key"])
            ],
            [],
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
                                map_body_quoted
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

def quoted_source_code_func(source_code):
    meta = {"start": (0,0,0), "end": (0,0,0)}

    (
        :def,
        Elixir.Map.put(meta, "docstring", None),
        [
            "__fython_get_file_source_code__",
            [],
            [],
            (
                :statements,
                meta,
                [(:string, meta, [source_code])]
            )
        ]
    )