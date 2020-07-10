def start():
    start(0, {"text_per_line": {}})

def start(count, state):
    # to make space between lines
    case count:
        0 -> None
        _ -> Elixir.IO.puts(" ")

    head = Elixir.IO.ANSI.format([
        :black, :bright , "[", :cyan, count |> Elixir.Kernel.to_string(), :black, :bright, "]: "
    ])
    user_input = Elixir.IO.gets(head) |> Elixir.Kernel.to_string()

    case Elixir.String.trim(user_input):
        "" -> start(count, state)
        _ ->
            state = case user_input |> Elixir.String.at(0):
                "%" ->
                    line_number = Elixir.String.replace_prefix(user_input, "%", "")
                        |> Elixir.String.replace("\n", "")
                        |> Elixir.String.to_integer()

                    text = state |> Elixir.Map.get("text_per_line") |> Elixir.Map.get(line_number)
                    case text:
                        None -> raise "Line code not found"
                        _ -> execute(text)
                    state
                _ ->
                    execute(user_input)
                    text_per_line = Elixir.Map.get(state, "text_per_line")

                    state
                        |> Elixir.Map.merge({
                            "text_per_line": Elixir.Map.merge(text_per_line, {count: user_input})
                        })

            start(count + 1, state)

def execute(text):
    result = Core.eval_string('<stdin>', text)

    case result:
        None -> None
        _ -> Elixir.IO.inspect(result)