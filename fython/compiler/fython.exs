File.read("/tmp/compiled_fython")
  |> elem(1)
  |> Code.eval_string
  |> Code.eval_quoted
  |> IO.inspect
