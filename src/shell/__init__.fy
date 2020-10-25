def start():
    start(0, {"text_per_line": {}, 'last_output': None}, [])

def start(count, state, env):
    # to make space between lines
    case count:
        0 -> None
        _ -> Elixir.IO.puts(" ")

    head = Elixir.IO.ANSI.format([
        :black, :bright , "[", :cyan, count |> Elixir.Kernel.to_string(), :black, :bright, "]: "
    ])
    user_input = Elixir.IO.gets(head) |> Elixir.Kernel.to_string()

    case Elixir.String.trim(user_input):
        "" -> start(count, state, env)
        _ ->
            (state, new_env) = case user_input |> Elixir.String.at(0):
                "_" ->
                    Elixir.IO.inspect(state['last_output'])
                    (state, env)
                "%" ->
                    line_number = Elixir.String.replace_prefix(user_input, "%", "")
                        |> Elixir.String.replace("\n", "")
                        |> Elixir.String.to_integer()

                    text = state |> Elixir.Map.get("text_per_line") |> Elixir.Map.get(line_number)
                    case text:
                        None -> raise "Line code not found"
                        _ ->
                            (result, new_env) = execute(text, env)

                            state = state |> Elixir.Map.merge({"last_output": result})

                            (state, new_env)
                _ ->
                    (result, new_env) = execute(user_input, env)
                    text_per_line = Elixir.Map.get(state, "text_per_line")

                    state = state
                        |> Elixir.Map.merge({
                            "last_output": result,
                            "text_per_line": Elixir.Map.merge(text_per_line, {count: user_input})
                        })

                    (state, new_env)

            start(count + 1, state, new_env)

def execute(text, env):
    (result, new_env) = Core.eval_string('<stdin>', text, env)
    Elixir.IO.inspect(result)
    (result, new_env)
