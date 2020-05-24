def create_doc(project_root):
    # 1º get lexed and parsed ast

    get_fython_files_in_path(project_root)
        |> Elixir.Enum.map(lambda module_name_n_full_path:
            (module_name, file_full_path) = module_name_n_full_path

            (:ok, text) = Elixir.File.read(file_full_path)
            ast = lexer_and_parser(text)

            get_doc_strings(ast)
        )


def get_fython_files_in_path(project_root):
    # TODO this functon must be in the language itself
    files_path = [project_root, "**/*.fy"]
        |> Elixir.Enum.join('/')
        |> Elixir.Path.wildcard()
        |> Elixir.Enum.map(lambda full_path:
            (Core.Generator.Compiler.get_module_name(project_root, full_path), full_path)
        )


def lexer_and_parser(text):
    # TODO this functon must be in the language itself
    lexed = Core.Lexer.execute(text)
    state = case Elixir.Map.get(lexed, "error"):
        None ->
            tokens = Elixir.Map.get(lexed, "tokens")
            Core.Parser.execute(tokens)
        _ ->
            lexed
    ast = Elixir.Map.get(state, 'node')


def get_doc_strings(node_ast):
    # receives a StatementsNode

    node_ast['statement_nodes']
        |> Elixir.Enum.map(lambda func_def_node:
            func_name = Elixir.Enum.join([
                func_def_node['var_name_tok']['value'],
                "/",
                Elixir.Enum.count(func_def_node['arg_name_toks'])
            ])
            docstring = func_def_node["docstring"] |> Map.get("value")

            (func_name, docstring)
        )
        |> Elixir.Enum.filter(lambda i: Elixir.Kernel.elem(i, 1) != None)
