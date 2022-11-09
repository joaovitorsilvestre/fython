def run(path):
    # TODO it should compile the tests module

    test_functions_per_module = Fytest.Discover.find_test_functions(path)
    Elixir.IO.puts('Colleted tests:')
    Elixir.IO.inspect(test_functions_per_module)
    run_tests(test_functions_per_module)

def run_tests(test_functions_per_module):
    results_per_module = test_functions_per_module
        |> Elixir.Enum.map(lambda (module, functions):
            results = functions
                |> Elixir.Enum.map(
                    lambda (test_name, arity):
                        execute_test(module, test_name, arity)
                )
            (module, results)
        )

    results_per_module
        |> Elixir.Enum.map(lambda (module, results):
            show_results(results)
        )

def show_results(results):
    passed = results
        |> Elixir.Enum.filter(lambda (status, _, _, _, _): status == :passed)
        |> Elixir.Enum.map(lambda (_, module, test_name, _, _):
            Elixir.IO.puts(Elixir.Enum.join(["PASSED: ", module, test_name]))
        )

    Elixir.IO.puts('=========================')

    failed = results
        |> Elixir.Enum.filter(lambda (status, _, _, _, _): status == :failed)
        |> Elixir.Enum.map(lambda (_, module, test_name, error, stacktrace):
            Elixir.IO.puts(Elixir.Enum.join(["FAILED: ", module, test_name]))
        )

def execute_test(module, test_name, _arity):
    try:
        Elixir.Kernel.apply(module, test_name, [])
        (:passed, module, test_name, None, None)
    except error:
        (:failed, module, test_name, error, __STACKTRACE__)
