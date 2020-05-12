def start():
    start(0, {"text_per_line": {}})

def start(count, state):
    # to make space between lines
    case count:
        0 -> None
        _ -> IO.puts(" ")

    head = IO.ANSI.format([
        :black, :bright , "[", :cyan, count |> to_string(), :black, :bright, "]: "
    ])
    user_input = IO.gets(head)

    case user_input |> String.trim():
        "" -> start(count, state)
        _ ->
            state = case user_input |> String.at(0):
                "%" ->
                    line_number = String.replace_prefix(user_input, "%", "")
                        |> String.replace("\n", "")
                        |> String.to_integer()

                    text = state |> Map.get("text_per_line") |> Map.get(line_number)
                    case text:
                        None -> raise "Line code not found"
                        _ -> execute(text)
                    state
                _ ->
                    execute(user_input)
                    text_per_line = Map.get(state, "text_per_line")

                    state
                        |> Map.merge({
                            "text_per_line": Map.merge(text_per_line, {count: user_input})
                        })

            start(count + 1, state)

def execute(text):
    result = Fcore.eval_string('<stdin>', text)

    case result:
        None -> None
        _ -> IO.inspect(result)