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
    {"ln": line, "col": col_start} = pos_start
    {"col": col_end} = pos_end

    raise Kernel.SyntaxError(message=msg, position=(line, col_start, col_end), source_code=state['source_code'])

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
        :struct_def,
        :struct
    ]

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

def is_calling_function_of_fython_module(node <- (:call, meta, [(:var, _, [_, being_called]), args, keywords, False])):
    # being_called
    #   "nome_funcao" -> False
    #   "Elixir.Module.nome_funcao" -> False
    #   "Module.nome_funcao" -> True

    case Elixir.String.contains?(being_called, '.'):
        False -> False
        True ->
            (function, modules) = being_called
                |> Elixir.String.split(".")
                |> Elixir.List.pop_at(-1)

            module = Elixir.Enum.join(modules, ".")

            case:
                Elixir.String.starts_with?(module, "Elixir.") -> False
                Elixir.String.starts_with?(module, "Erlang.") -> False
                True -> True
