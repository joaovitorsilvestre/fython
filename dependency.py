try:
    from functools import reduce
except:
    pass

data = {
    'parser':     {'lexer', 'kernel'},
    'lexer':      {'kernel'},
}


def recur(info):
    data = info['data']

    ordered = set(item for item, dep in data.items() if not dep)

    print('ordered', ordered)

    if not ordered:
        return {'data': data, 'result': info['result']}

    data = {
        item: (dep - ordered) for item, dep in data.items() if item not in ordered
    }

    info = {'data': data, 'result': info['result'] + sorted(ordered)}

    return recur(info)


def first(data):
    for k, v in data.items():
        v.discard(k)  # Ignore self dependencies

    extra_items_in_deps = reduce(set.union, data.values()) - set(data.keys())

    data.update({item: set() for item in extra_items_in_deps})

    result = recur({'data': data, 'result': []})
    if result['data']:
        raise ValueError("A cyclic dependency exists amongst %r" % data)

    return result['result']


print(first(data))

# def topology_sort(info <- {"data": data, "result": result}):
#     ordered = data
#         |> Elixir.Map.to_list()
#         |> Elixir.Enum.filter(lambda (item, deps): deps == Elixir.MapSet.new())
#         |> Elixir.Enum.map(lambda (item, deps): item)
#         |> Elixir.MapSet.new()
#
#     case ordered == Elixir.MapSet.new():
#         True -> info
#         False ->
#             data = data
#                 |> Elixir.Map.to_list()
#                 |> Elixir.Enum.filter(lambda (item, deps):
#                     Elixir.MapSet.member?(item, ordered)
#                 )
#                 |> Elixir.Enum.map(lambda (item, deps):
#                     Elixir.MapSet.difference(deps, ordered)
#                 )
#                 |> Elixir.MapSet.new()
#
#             info = {"result": [*result, *ordered], "data": data}
#
#             topology_sort(info)
#
#
# def topology_sort(data):
#     data = data
#         |> Elixir.Map.to_list()
#         |> Elixir.Enum.map(lambda (item, deps):
#             # Ignore self dependencies
#             deps = Elixir.MapSet.difference(
#                 Elixir.MapSet.new(deps),
#                 Elixir.MapSet.new([item])
#             )
#             (item, deps)
#         )
#         |> Elixir.Map.new()
#
#     extra_items_in_deps = data
#         |> Elixir.Map.values()
#         |> Elixir.Enum.reduce(lambda acc, deps:
#             Elixir.MapSet.union(acc, deps)
#         )
#         |> Elixir.MapSet.difference(Elixir.MapSet.new(Elixir.Map.keys(data)))
#
#     data = extra_items_in_deps
#         |> Elixir.Enum.map(lambda item: (item, Elixir.MapSet.new()))
#         |> Elixir.Map.new()
#         |> Elixir.Map.merge(data)
#
#     result = topology_sort({'data': data, 'result': []})
#
#     case result['data']:
#         {} -> result['result']
#         _ ->
#             # raise ValueError("A cyclic dependency exists amongst %r" % data)
#             Elixir.IO.inspect("A cyclic dependency exists amongst")
#             raise "A cyclic dependency exists amongst" # TODO
#
# def run():
#     data = {
#         'parser': ['lexer', 'kernel'],
#         'lexer': ['kernel']
#     }
#     topology_sort(data)