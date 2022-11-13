def run(path):
    # TODO it should compile the tests module

    test_functions_per_module = Fytest.Discover.find_test_functions(path)
    Elixir.IO.puts('Colleted tests:')
    Elixir.IO.inspect(test_functions_per_module)

    results = Fytest.Executor.run_tests(test_functions_per_module)
    show_results(results)


def show_results(results):
    (success_results, failed_results) = group_results_by_status(results)

    success_results |> Elixir.Enum.each(&show_result/1)
    Elixir.IO.puts('=========================')
    failed_results |> Elixir.Enum.map(&show_result/1)


def group_results_by_status(results):
    results
        |> Elixir.Enum.split_with(lambda (status, _, _, _, _): status == :passed)

def simplify_module_name(module):
    # Remove Fython.Test from the name of module
    module
        |> Elixir.Atom.to_string()
        |> Elixir.String.split('.')
        |> Elixir.Enum.slice(2..-1)

def show_result((:failed, module, test_name, error, stacktrace)):
    Elixir.IO.puts(Elixir.Enum.join(["FAILED: ", simplify_module_name(module), '.', test_name]))
#
def show_result((:passed, module, test_name, None, None)):
    Elixir.IO.puts(Elixir.Enum.join(["PASSED: ", simplify_module_name(module), '.', test_name]))