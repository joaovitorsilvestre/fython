def create_doc(project_root):
    # 1º get lexed and parsed ast

    docs = get_fython_files_in_path(project_root)
        |> Elixir.Enum.map(lambda module_name_n_full_path:
            (module_name, file_full_path) = module_name_n_full_path
            module_name = Elixir.String.replace_leading(module_name, "Fython.", '')

            (:ok, text) = Elixir.File.read(file_full_path)
            ast = lexer_and_parser(text)

            (module_name, get_doc_strings(ast), file_full_path)
        )
        |> Elixir.Enum.sort_by(lambda i: Elixir.Kernel.elem(i, 0))
        |> Elixir.Enum.reduce(
            [],
            lambda x, acc:
                (module_name, docs, file_full_path) = x
                modules = Elixir.String.split(module_name, '.')

                data = {
                    'name': modules, 'text': '',
                    'functions': Elixir.Enum.map(
                        docs,
                        lambda i:
                            (func_name, docstring) = i
                            {'func_name': func_name, 'docstring': docstring}
                    )
                }

                Elixir.List.insert_at(acc, -1, data)
        )
        |> Elixir.Jason.encode!()

    Elixir.File.write!(
        "/home/joao/fython/fy_doc/fy_doc/front/public/docs.json",
        docs
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
            docstring = func_def_node["docstring"]['value'] if func_def_node["docstring"] else None

            (func_name, docstring)
        )
        |> Elixir.Enum.filter(lambda i: Elixir.Kernel.elem(i, 1) != None)
