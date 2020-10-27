def start():
    start(
        0,
        {
            "text_per_line": {},
            'last_output': None,
            'current_command': '' # multiline command
        },
        [],
    )

def start(count, state, env):
    # to make space between lines
    is_multiline_command = state['current_command'] != ''

    case (is_multiline_command, count):
        (True, _) -> None
        (False, 0) -> Elixir.IO.puts(" ")
        _ -> None

    head = case is_multiline_command:
        False -> Elixir.IO.ANSI.format([
            :black, :bright , "[", :cyan, count |> Elixir.Kernel.to_string(), :black, :bright, "]: "
        ])
        True -> "     "

    user_input = Elixir.IO.gets(head) |> Elixir.Kernel.to_string() |> Elixir.String.trim_trailing()
    current_line = user_input
    user_input = case is_multiline_command:
        False -> user_input
        True -> Elixir.Enum.join([state['current_command'], '\n', user_input])

    case:
        user_input == "" -> start(count, state, env)
        True ->
            first_char = Elixir.String.at(user_input, 0)
            last_char = Elixir.String.last(user_input)

            (count, state, new_env) = case:
                first_char == '_' and not is_multiline_command ->
                    Elixir.IO.inspect(state['last_output'])
                    (count + 1, state, env)
                first_char == "%" and not is_multiline_command ->
                    line_number = Elixir.String.replace_prefix(user_input, "%", "")
                        |> Elixir.String.replace("\n", "")
                        |> Elixir.String.to_integer()

                    text = state |> Elixir.Map.get("text_per_line") |> Elixir.Map.get(line_number)
                    case text:
                        None -> raise "Line code not found"
                        _ ->
                            (result, new_env) = execute(text, env)

                            state = state |> Elixir.Map.merge({"last_output": result})

                            (count + 1, state, new_env)
                last_char == ':' ->
                    state = Elixir.Map.merge(state, {'current_command': user_input})
                    (count, state, env)
                (not is_multiline_command) or (is_multiline_command and current_line == '') ->
                    (result, new_env) = execute(user_input, env)

                    state = state
                        |> Elixir.Map.merge({
                            "last_output": result,
                            'current_command': '', # reset multiline command
                            "text_per_line": Elixir.Map.merge(state['text_per_line'], {count: user_input})
                        })

                    (count + 1, state, new_env)
                is_multiline_command ->
                    state = Elixir.Map.merge(state, {'current_command': user_input})
                    (count, state, env)

            start(count, state, new_env)

def execute(text, env):
    try:
        (result, new_env) = Core.eval_string('<stdin>', text, env)
        Elixir.IO.inspect(result)
        (result, new_env)
    except error:
        # TODO this global handler for errors must be in the eval string code
        Elixir.IO.puts("Exception")
        Elixir.IO.puts(Elixir.Exception.format_stacktrace(__STACKTRACE__))
        Elixir.IO.inspect(__STACKTRACE__)
        (None, env)
