def digists():
    '0123456789'

def letters():
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

def letters_digits():
    Elixir.Enum.join([letters(), digists()])

def identifier_chars(first_char):
    case first_char:
        True -> Elixir.Enum.join([letters(), "_"])
        False -> Elixir.Enum.join([letters(), digists(), "_.?!"])

def atom_chars(first_char):
    case first_char:
        True -> Elixir.Enum.join([letters(), "_"])
        False -> Elixir.Enum.join([letters(), digists(), "_?!"])
