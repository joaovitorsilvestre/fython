def run_tests(test_functions_per_module):
    results = test_functions_per_module
        |> Elixir.Enum.map(lambda (module, functions):
            results = functions
                |> Elixir.Enum.map(
                    lambda (test_name, arity):
                        execute_test(module, test_name, arity)
                )
            results
        )
        |> Elixir.List.flatten()

def execute_test(module, test_name, _arity):
    try:
        Elixir.Kernel.apply(module, test_name, [])
        (:passed, module, test_name, None, None)
    except error:
        (:failed, module, test_name, error, __STACKTRACE__)
