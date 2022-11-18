def has_error(state):
    Elixir.Map.get(state, "error") != None

def tok_matchs(tok, type):
    Elixir.Map.get(tok, "type") == type

def tok_matchs(tok, type, value):
    Elixir.Map.get(tok, "type") == type and Elixir.Map.get(tok, "value") == value

def get_next_tok(state):
    idx = state |> Elixir.Map.get("current_tok_idx")
    tokens = state |> Elixir.Map.get("tokens")
    idx = idx + 1
    tokens |> Elixir.Enum.at(idx)

def set_error(state, msg, pos_start, pos_end):
    case Elixir.Map.get(state, 'error'):
        None ->
            state = Elixir.Map.put(
                state, "error", {"msg": msg, "pos_start": pos_start, "pos_end": pos_end}
            )
            state
        _ -> state

def nodes_types():
    [
        :number,
        :atom,
        :var,
        :string,
        :unary,
        :list,
        :tuple,
        :binop,
        :pattern,
        :if,
        :func,
        :statements,
        :lambda,
        :def,
        :static_access,
        :raise,
        :assert,
        :pipe,
        :map,
        :case,
        :call,
        :try,
        :range,
        :struct,
        :struct_call
    ]

def extract_module_structs(node <- (:statements, meta, nodes)):
    (structs, remaining) = Elixir.Enum.split_with(nodes, lambda (node_type, _, _): node_type == :struct)

    # put structs back inside a statements block
    structs = Elixir.Enum.map(
        structs,
        lambda (:struct, meta, body): (:statements, meta, [(:struct, meta, body)])
    )

    (structs, (:statements, meta, remaining))

def is_struct_reference((:var, _, [_, being_called])):
    # All structs begin with
    # Example.User -> returns true
    # Example.user -> returns false

    first_letter = being_called
        |> Elixir.String.split('.')
        |> Elixir.Enum.at(-1)
        |> Elixir.String.graphemes()
        |> Elixir.Enum.at(0)

    letters = Core.Lexer.Consts.letters()

    Elixir.String.contains?(letters, first_letter) and first_letter == Elixir.String.upcase(first_letter)

def is_struct_reference(_):
    False
