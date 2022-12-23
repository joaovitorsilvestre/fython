def parallel_map(collection, func):
    # Executs a traditional map in parallel
    # If any task throws an exception, the first one to throw will be re-raised

    collection
        |> Elixir.Enum.map(lambda i:
            Elixir.Task.async(lambda:
                # Prevents errors to break current process.
                # otherwise we will not be able to catch
                try:
                    (:ok, func(i))
                except error:
                    (:error, error, __STACKTRACE__)
            )
        )
        |> Elixir.Enum.map(lambda i:
            result = Elixir.Task.await(i, :infinity)

            case result:
                (:ok, result) -> result
                (:error, e, stacktrace) -> Elixir.Kernel.reraise(e, stacktrace)
        )