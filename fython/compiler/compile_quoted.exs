defmodule M do
  def f(quoted_path) do
    root = "/#{quoted_path |> Enum.slice(0..-2) |> Enum.join("/")}"
    quoted_path = "/#{Enum.join(quoted_path, "/")}"

    quoted = File.read(quoted_path)
      |> elem(1)
      |> Code.eval_string
      |> elem(0)
      |> Code.compile_quoted

    result = quoted
      |> Enum.each(fn {module, content} ->
        File.write(
          "#{root}/compiled/#{module |> to_string}.beam",
          content,
          mode: :binary
        )
      end)

    IO.puts("result: ")
    IO.inspect(quoted)

    case {quoted, result} do
      {[], :ok} -> IO.puts('compilation result: FAILED')
      {_, :error} -> IO.puts('compilation result: FAILED')
       _ -> IO.puts('compilation result: SUCCESS')
    end

  end
end

M.f(System.argv())