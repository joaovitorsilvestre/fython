def digists():
    '0123456789'

def letters():
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

def letters_digits():
    Enum.join([letters(), digists()])

def identifier_chars(firs_char):
    case firs_char:
        True -> Enum.join([letters(), "_"])
        False -> Enum.join([letters(), digists(), "_.?!"])
