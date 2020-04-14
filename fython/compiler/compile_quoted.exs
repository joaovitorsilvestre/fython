defmodule M do
  def f(quoted_path) do
    root = "/#{quoted_path |> Enum.slice(0..-2) |> Enum.join("/")}"
    quoted_path = "/#{Enum.join(quoted_path, "/")}"

    File.read(quoted_path)
      |> elem(1)
      |> Code.eval_string
      |> elem(0)
      |> Code.compile_quoted
      |> Enum.each(fn {module, content} ->
        File.write(
          "#{root}/compiled/#{module |> to_string}.beam",
          content,
          mode: :binary
        )
      end)
  end
end

M.f(System.argv())