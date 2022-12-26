def get_functions_defs(project_path):
    modules_asts = project_path
        |> get_modules_asts()
        |> extract_functions()

def get_modules_asts(project_path):
    # returns [(module_name, node)]
    Core.Code.get_fython_files_in_folder(project_path)
        |> Enum.map(lambda file:
            module_name = Core.Code.get_module_name(project_path, file)
            config = {'file': file}

            text = Elixir.File.read(file) |> Elixir.Kernel.elem(1)
            lexed = Core.Lexer.execute(text)
            {'node': node} = Core.Parser.execute(lexed['tokens'], text, config)
            (module_name, node, text)
        )

def extract_functions(modules_asts):
    modules_asts
        |> Enum.map(lambda (module_name, ast, text):
            state = {"def_func_nodes": [], 'text': text}

            [node, state] = Core.Parser.Traverse.run(
                ast, state, &get_functions_defs/2
            )
            (module_name, state['def_func_nodes'])
        )
        |> Elixir.List.flatten()

def get_functions_defs(node <- (:def, meta, _), state):
    {"start": (_, ln, _)} = meta

    text = state['text']
        |> Elixir.String.split('\n')
        |> Enum.at(ln)
        |> Elixir.String.replace_prefix('def ', '')
        |> Elixir.String.replace_suffix(':', '')

    state = Map.put(
        state,
        'def_func_nodes',
        Elixir.List.flatten([state['def_func_nodes'], text])
    )

    [node, state]

def get_functions_defs(node <- (nodetype, meta, _), state):
    [node, state]