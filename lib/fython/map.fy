def get(map, key):
    get(map, key, None)

def get(map, key, default):
    Elixir.Map.get(map, key, default)

def to_list(map):
    Elixir.Map.to_list(map)

def new(map):
    Elixir.Map.new(map)

def merge(map):
    Elixir.Map.merge(map)

def keys(map):
    Elixir.Map.keys(map)

def pop(map):
    Elixir.Map.pop(map)

def put(map):
    Elixir.Map.put(map)