def execute(text):
    state = {
        "text": None,
        "position": None,
        "prev_position": None,
        "current_ident_level": 0,
        "error": None,
        "current_char": None,
        "tokens": [],
        "being_scaped": False
    }

    # Theres tokens that are multiline, like multiline string
    # We can parallelize by line and let each part of the token
    # in separated lines to be processed
    # This bloc of code merges all multiline tokens into a single
    # line to ensure that they are processed in same parser

    tokens_that_are_multiline = ['"""']

    lines = text
        |> Elixir.String.split("\n")
        |> Elixir.Enum.reduce(
            {"lines": [], "open_multiline": False},
            lambda line, acc:
                has_multiline_token = Elixir.String.contains?(line, tokens_that_are_multiline)

                merge_last = lambda acc, line:
                    last_line = Elixir.Enum.at(acc['lines'], -1)
                    line = Elixir.Enum.join([last_line, '\n',  line])

                    lines = Elixir.List.replace_at(acc['lines'], -1, line)
                    Elixir.Map.put(acc, 'lines', lines)

                acc = case (acc['open_multiline'], has_multiline_token):
                    (False, False) ->
                        Elixir.Map.put(acc, "lines", [*acc['lines'], line])
                    (False, True) ->
                        acc
                            |> Elixir.Map.put('open_multiline', True)
                            |> Elixir.Map.put("lines", [*acc['lines'], line])
                    (True, True) ->
                        acc
                            |> merge_last(line)
                            |> Elixir.Map.put('open_multiline', False)
                    (True, False) ->
                        acc |> merge_last(line)
        )
        |> Elixir.Map.get("lines")

    all_lines_parsed = lines
        |> Elixir.Enum.with_index()
        |> Elixir.Enum.map(lambda line_n_number:
            (text, index) = line_n_number

            (idx, ln) = case index:
                0 -> (0, 0)
                _ ->
                    prev_lines = lines
                        |> Elixir.Enum.slice(Elixir.Range.new(0, index - 1))

                    ln = prev_lines
                        |> Elixir.Enum.map(lambda i: Elixir.String.split(i, '\n'))
                        |> Elixir.List.flatten()
                        |> Elixir.Enum.count()

                    idx = prev_lines
                        |> Elixir.Enum.reduce(0, lambda i, acc: Elixir.String.length(i) + acc)

                    (idx, ln)
            state
                |> Elixir.Map.put("text", text)
                |> Elixir.Map.put("position", position(-1, ln, -1))
                |> advance()
        )
        |> parallel_map(&parse/1)

    first_with_error = Elixir.Enum.find(all_lines_parsed, lambda i: i['error'] != None)

    tokens = all_lines_parsed
        |> Elixir.Enum.reduce(
            [],
            lambda i, acc:
                Elixir.List.flatten([acc, i['tokens']])
        )

    last_position = position(
        Elixir.String.length(text) - 1,
        (Elixir.String.split(text, "\n") |> Elixir.Enum.count()) - 1,
        (Elixir.String.split(text, "\n") |> Elixir.List.last() |> Elixir.String.length()) -1
    )

    state
        |> Elixir.Map.put("error", first_with_error['error'] if first_with_error else None)
        |> Elixir.Map.put("tokens", tokens)
        |> Elixir.Map.put("position", last_position)
        |> Core.Lexer.Tokens.add_eof_token()

def parallel_map(collection, func):
    collection
        |> Elixir.Enum.map(lambda i: Elixir.Task.async(lambda: func(i)))
        |> Elixir.Enum.map(lambda i: Elixir.Task.await(i, :infinity))

def position(idx, ln, col):
    {"idx": idx, "ln": ln, "col": col}

def advance(state):
    idx = state["position"]["idx"]
    ln = state["position"]["ln"]
    col = state["position"]["col"]
    text = state["text"]
    being_scaped = state["being_scaped"]

    prev_position = state['position']

    being_scaped = being_scaped == False and idx > 0 and Elixir.String.at(text, idx) == "\\"

    idx = idx + 1
    current_char = Elixir.String.at(text, idx)
    next_char = Elixir.String.at(text, idx + 1)
    new_pos = case current_char == '\n':
        True -> position(idx, ln + 1, -1)
        False -> position(idx, ln, col + 1)

    new_state = {
        "position": new_pos,
        "prev_position": prev_position,
        "current_char": current_char,
        "next_char": next_char,
        "being_scaped": being_scaped
    }

    Elixir.Map.merge(state, new_state)

def set_error(state, error):
    Elixir.Map.put(
        state,
        "error",
        {
            "msg": error,
            "pos_start": state['position'],
            "pos_end": state['position']
        }
    )

def parse(state):
    case state["error"]:
        None ->
            cc = state["current_char"]
            nc = state["next_char"]
            pos = state["position"]

            case:
                cc == None -> state
                cc == "#" -> parse(skip_comment(state))
                cc == " " and pos["col"] == 0 -> parse(make_ident(state))
                cc == " " or cc == '\t' -> parse(advance(state))
                cc == "\n" ->
                    state
                        |> Elixir.Map.put("current_ident_level", 0)
                        |> Core.Lexer.Tokens.add_token("NEWLINE")
                        |> advance()
                        |> parse()
                cc == ':' -> parse(make_do_or_atom(state))
                cc == 'c' and (nc == "'" or nc == '"') -> parse(make_string(advance(state), :charlist))
                cc == 'r' and (nc == "'" or nc == '"') -> parse(make_string(advance(state), :regex))
                cc == "'" or cc == '"' -> parse(make_string(state, :string))
                Elixir.String.contains?(Core.Lexer.Consts.identifier_chars(True), cc) ->
                    state |> make_identifier() |> parse()
                cc == "&" -> simple_maker(state, "ECOM")
                Elixir.String.contains?(Core.Lexer.Consts.digists(), cc) -> parse(make_number(state))
                cc == "^" -> simple_maker(state, "PIN")
                cc == "," -> simple_maker(state, "COMMA")
                cc == "+" -> simple_maker(state, "PLUS")
                cc == "/" -> simple_maker(state, "DIV")
                cc == '(' -> simple_maker(state, 'LPAREN')
                cc == ')' -> simple_maker(state, 'RPAREN')
                cc == '[' -> simple_maker(state, 'LSQUARE')
                cc == ']' -> simple_maker(state, 'RSQUARE')
                cc == '{' -> simple_maker(state, 'LCURLY')
                cc == '}' -> simple_maker(state, 'RCURLY')
                cc == '-' -> double_maker(state, "MINUS", [(">", "ARROW")])
                cc == '*' -> double_maker(state, "MUL", [("*", "POW")])
                cc == '>' -> double_maker(state, "GT", [("=", "GTE")])
                cc == '<' -> double_maker(state, "LT", [("=", "LTE"), ('-', 'LARROW')])
                cc == '=' -> double_maker(state, "EQ", [("=", "EE")])
                cc == '!' -> expected_double_maker(state, "!", "NE", "=")
                cc == '.' -> expected_double_maker(state, ".", "RANGE", ".")
                cc == '|' -> expected_double_maker(state, "|", "PIPE", ">")
                True -> set_error(state, Elixir.Enum.join(["IllegalCharError: ", cc]))
        _ -> state

def simple_maker(st, type):
    st
        |> Core.Lexer.Tokens.add_token(type)
        |> advance()
        |> parse()

def double_maker(st, type, sub_types):
    st = advance(st)
    cc = st["current_char"]

    sub_type = Elixir.Enum.find(sub_types, lambda i: Elixir.Kernel.elem(i, 0) == cc)

    case sub_type:
        None ->
            st |> Core.Lexer.Tokens.add_token(type) |> parse()
        _ ->
            (_symbol, tok_type) = sub_type
            st |> Core.Lexer.Tokens.add_token(tok_type) |> advance() |> parse()


def expected_double_maker(st, first, type, expected):
    st = advance(st)
    cc = st["current_char"]

    case:
        cc == expected -> st |> Core.Lexer.Tokens.add_token(type) |> advance() |> parse()
        True -> st |> set_error(Elixir.Enum.join(["Expected '", expected, "' after '", first, "'"]))

def make_ident(state):
    first_char = state["current_char"]

    state = loop_while(state, lambda cc, _, _:
        cc != None and cc == " "
    )

    total_spaces = Elixir.Enum.join([first_char, Elixir.Map.get(state, "result")]) |> Elixir.String.length()

    state = case rem(total_spaces, 4) != 0:
        True -> set_error(state, "Identation problem")
        False -> state |> Elixir.Map.put("current_ident_level", max(0, total_spaces))

    state |> Elixir.Map.delete("result")

def loop_while(st, func):
    st = advance(st)
    cc = st["current_char"]
    being_scaped = st["being_scaped"]
    result = Elixir.Map.get(st, "result")

    result_callback = func(cc, st['next_char'], being_scaped)

    case result_callback:
        True -> Elixir.Map.put(st, "result", Elixir.Enum.join([result, cc])) |> loop_while(func)
        False -> st
        :skip_cc -> loop_while(st, func)
        _ -> set_error(st, result_callback)

def loop_while_new(st, func):
    st = advance(st)
    cc = st["current_char"]
    being_scaped = st["being_scaped"]
    result = Elixir.Map.get(st, "result")

    [continue, value] = func(cc, st['next_char'], being_scaped)

    case [continue, value]:
        [True, None] ->
            loop_while_new(st, func)
        [:skip_next, _] ->
            st = Elixir.Map.put(st, "result", Elixir.Enum.join([result, value]))
            loop_while_new(advance(st), func)
        [True, _] ->
            st = Elixir.Map.put(st, "result", Elixir.Enum.join([result, value]))
            loop_while_new(st, func)
        [False, _] -> st
        _ -> set_error(st, value)


def loop_until_sequence(state, expected_seq):
    state = advance(state)
    idx = state["position"]["idx"]
    text = state['text']
    cc = state["current_char"]

    result = Elixir.Enum.join([Elixir.Map.get(state, "result", ""), cc])

    exp_seq_size = Elixir.String.length(expected_seq)

    this_seq = Elixir.String.slice(text, Elixir.Range.new(idx, idx + exp_seq_size - 1))

    state = case:
        this_seq == expected_seq ->
            # skip the expected_seq
            state = Elixir.Range.new(0, exp_seq_size - 1)
                |> Elixir.Enum.reduce(
                    state,
                    lambda _, acc: advance(acc)
                )

            state
        cc == None -> set_error(state, Elixir.Enum.join(["expected: ", expected_seq]))
        True ->
            state = Elixir.Map.put(state, "result", result)
            loop_until_sequence(state, expected_seq)

    state

def make_do_or_atom(state):
    pos_start = state["position"]
    state = advance(state)

    first_char = state["current_char"]

    valid_letter = not (first_char in ["'", '"', None]) and Elixir.String.contains?(Core.Lexer.Consts.atom_chars(True), first_char)
    is_atom_of_string = Elixir.Enum.member?(['"', "'"], first_char)

    case:
        valid_letter or is_atom_of_string ->
            state = advance(state) if is_atom_of_string else state

            state = state
                |> Elixir.Map.put("result",  state["current_char"])
                |> loop_while(lambda cc, _, _:
                    case is_atom_of_string:
                        True -> cc != first_char
                        False -> cc != None and Elixir.String.contains?(Core.Lexer.Consts.atom_chars(False), cc)
                )

            state = advance(state) if is_atom_of_string else state

            state = state
                |> Core.Lexer.Tokens.add_token(
                    "ATOM", Elixir.Map.get(state, "result"), pos_start
                )
                |> Elixir.Map.delete("result")

            state
        True ->
            state
                |> advance()
                |> Core.Lexer.Tokens.add_token("DO")


def make_string(state, type) if type in [:string, :regex, :charlist]:
    pos_start = state["position"]
    string_char_type = state["current_char"] # ' or "

    next_char = advance(state)['current_char']
    next_next_char = advance(state) |> advance() |> Map.get('current_char')

    case Elixir.Enum.join([string_char_type, next_char, next_next_char]) == '"""':
        True ->
            state = advance(state)
                |> advance()
                |> advance()
                |> loop_until_sequence('"""')

            (result, state) = Elixir.Map.pop(state, "result")

            state
                |> Core.Lexer.Tokens.add_token(
                    "MULLINESTRING", result, pos_start
                )
        False ->
            state = loop_while_new(state, lambda cc, nc, being_scaped:
                case:
                    cc == "\\" and being_scaped -> [True, None]
                    nc == "n" and cc == "\\" and being_scaped == False -> [:skip_next, "\n"]
                    nc == '"' and cc == "\\" and being_scaped == False -> [:skip_next, '"']
                    cc == string_char_type and being_scaped == True -> [True, cc]
                    cc == string_char_type and being_scaped == False -> [False, cc]
                    True -> [True, cc]
            )

            # to advance the end string char
            state = advance(state)

            string = state |> Elixir.Map.get("result", "")

            token_type = case type:
                :string -> "STRING"
                :regex -> "REGEX"
                :charlist -> "CHARLIST"

            state
                |> Core.Lexer.Tokens.add_token(
                    token_type, string, pos_start
                )
                |> Elixir.Map.delete("result")

def skip_comment(state):
    state = advance(state)

    state = loop_while(state, lambda cc, _, _:
        cc != '\n' and cc != None
    )
    Elixir.Map.delete(state, "result")

def make_number(state):
    pos_start = state["position"]
    first_number = state["current_char"]

    state = loop_while(state, lambda cc, nc, _:
        valid_num_char = case cc:
            None -> False
            _ -> Elixir.String.contains?(Elixir.Enum.join([Core.Lexer.Consts.digists(), '._']), cc)

        case (valid_num_char, cc, nc):
            (False, _, _) -> False
            (True, ".", ".") -> False  # Range
            (True, _, _) -> True
            _ -> False
    )

    result = Elixir.Enum.join([first_number, Elixir.Map.get(state, "result")])
    result = Elixir.String.replace(result, "_", "")

    state = case:
        Elixir.String.contains?(result, '.') ->
            state
                |> Core.Lexer.Tokens.add_token(
                    "FLOAT", Elixir.Float.parse(result) |> Elixir.Kernel.elem(0), pos_start
                )
        True ->
            state
                |> Core.Lexer.Tokens.add_token(
                    "INT", Elixir.Integer.parse(result) |> Elixir.Kernel.elem(0), pos_start
                )

    state |> Elixir.Map.delete("result")

def make_identifier(state):
    pos_start = state["position"]
    first_char = state["current_char"]

    state = loop_while(state, lambda cc, nc, _:
        cc != None and Elixir.String.contains?(Core.Lexer.Consts.identifier_chars(False), cc) and not (cc == "." and nc == ".")
    )

    result = Elixir.Enum.join([first_char, Elixir.Map.get(state, "result")])

    type = case Elixir.Enum.member?(Core.Lexer.Tokens.keywords(), result):
        True -> "KEYWORD"
        False -> "IDENTIFIER"

    state
        |> Core.Lexer.Tokens.add_token(type, result, pos_start)
        |> Elixir.Map.delete("result")