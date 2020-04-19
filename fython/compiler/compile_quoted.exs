defmodule M do
  def f([quoted_as_string, project_path]) do
    Code.append_path("#{project_path}/compiled")

    quoted = quoted_as_string
      |> Code.eval_string
      |> elem(0)
      |> Code.compile_quoted

    result = quoted
      |> Enum.each(fn {module, content} ->
        IO.puts("args---")
        IO.inspect("#{project_path}/compiled/#{module |> to_string}.beam")
        IO.inspect(content)
        IO.inspect(:binary)


        File.write(
          "#{project_path}/compiled/#{module |> to_string}.beam",
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