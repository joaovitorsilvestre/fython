defmodule M do
  def f(quoted_path) do
    root = "/#{quoted_path |> Enum.slice(0..-2) |> Enum.join("/")}"
    quoted_path = "/#{Enum.join(quoted_path, "/")}"

    [{json, content}] = Code.compile_string(M.get_json_lib())

    File.write(
      "#{root}/compiled/#{json |> to_string}.beam",
      content,
      mode: :binary
    )

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
  def get_json_lib() do
    """
    defmodule JSON do
      import String

      def parse( content ) do
        case parse_content(content) do
          { value, "" } -> value
          { _, _ } -> raise "crap"
        end

      end

      def parse_content( << m,  rest :: binary >> ) when m in '0123456789-', do: parse_number << m, rest :: binary >>
      def parse_content( << ?", rest :: binary >> ), do: rest |> parse_string
      def parse_content( << ?{, rest :: binary >> ), do: lstrip(rest) |> parse_object
      def parse_content( << ?[, rest :: binary >> ), do: lstrip(rest) |> parse_array

      def parse_string( << c, rest :: binary >> ), do: rest |> parse_string [c]
      def parse_string( << ?", rest :: binary >>, acc ), do: { to_string(Enum.reverse(acc)), rest }
      def parse_string( << c, rest :: binary >>, acc ), do: rest |> parse_string [c | acc]

      def parse_number( << m, rest :: binary >> ), do: rest |> parse_number [m]
      def parse_number( << ?., rest :: binary >>, acc ), do: rest |> parse_float [ "." | acc ]
      def parse_number( << m, rest :: binary >>, acc ) when m in '0123456789-', do: rest |> parse_number [ m | acc ]
      def parse_number( << rest :: binary >>, acc ), do: { Enum.reverse(acc) |> to_string |> String.to_integer, rest }

      def parse_float( << m, rest :: binary >>, acc ) when m in '0123456789-', do: rest |> parse_float [ m | acc ]
      def parse_float( << rest :: binary >>, acc ), do: { to_string(Enum.reverse(acc)) |> String.to_float, rest }

      def parse_array( content ), do: parse_array([], content)
      def parse_array( acc, << rest :: binary >> ) do
        { value, rest } = parse_content rest

        acc = [ value | acc ]

        case lstrip(rest) do
          << ?], rest :: binary >> -> { Enum.reverse(acc), rest }
          << ?,, rest :: binary >> -> parse_array acc, lstrip(rest)
        end
      end

      def parse_object( content ), do: parse_object(%{}, content)
      def parse_object( acc, << rest :: binary >> ) do
        { key, rest } = parse_content rest
        { value, rest } = lstrip(rest) |> parse_object_value

        acc = Map.put acc, key, value

        case lstrip(rest) do
          << ?}, rest :: binary >> -> { acc, rest }
          << ?,, rest :: binary >> -> parse_object acc, lstrip(rest)
        end
      end

      def parse_object_value( << ?:, rest :: binary >> ), do: lstrip(rest) |> parse_object_value
      def parse_object_value( rest ), do: parse_content rest
    end
    """
  end
end

M.f(System.argv())