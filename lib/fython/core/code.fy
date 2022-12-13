def compile_project(project_path):
    compile_project(project_path, "_compiled", None)

def compile_project(project_path, destine, bootstrap_prefix):
    # start elixir compiler
    Erlang.application.start(:compiler)
    Erlang.application.start(:elixir)

    # If it's a absolute path we will not add the root as parent
    compiled_folder = case Elixir.String.starts_with?(destine, "/"):
        True -> destine
        False -> [project_path, destine] |> Elixir.Enum.join('/')

    # Ensure compiled folder is created
    Elixir.File.mkdir_p!(compiled_folder)

    files = get_fython_files_in_folder(project_path)
    compile_files(project_path, files, compiled_folder, bootstrap_prefix)

def get_fython_files_in_folder(project_path):
    [project_path, "**/*.fy"]
        |> Elixir.Enum.join('/')
        |> Elixir.Path.wildcard()


def compile_files(project_path, files, compiled_folder, bootstrap_prefix):
    # files: [a.fy, folder/b.fy, etc]

    modules_ready_to_be_saved = files
        |> Itertools.parallel_map(lambda file:
            (child_modules, parent_module) = pre_compile_file(project_path, file, bootstrap_prefix)
            (
                file,
                (child_modules, parent_module)
            )
        )

    child_modules = modules_ready_to_be_saved
        |> Elixir.Enum.map(lambda (file, (childs, _parent)): (file, childs))
        |> Elixir.Enum.filter(lambda (file, childs): Elixir.Enum.count(childs) > 0)

    parent_modules = modules_ready_to_be_saved
        |> Elixir.Enum.map(lambda (file, (_childs, parent)): (file, parent))

    # We need to compile child modules first. Child modules are structs, protocols, etc
    child_modules
        |> Elixir.List.flatten()
        |> Elixir.Enum.each(
            lambda (file, childs):
                Elixir.Enum.each(
                    childs,
                    lambda (m_name, ast):
                        save_module(m_name, file, compiled_folder, ast)
                )
        )

    parent_modules
        |> Elixir.List.flatten()
        |> Elixir.Enum.each(
            lambda (file, (m_name, ast)): save_module(m_name, file, compiled_folder, ast)
        )


def pre_compile_file(project_root, file_full_path):
    pre_compile_file(project_root, file_full_path, None)

def pre_compile_file(project_root, file_full_path, bootstrap_prefix):
    module_name = get_module_name(project_root, file_full_path, bootstrap_prefix)

    Elixir.IO.puts(Elixir.Enum.join(["Compiling module: ", module_name]))

    (:ok, file_content) = Elixir.File.read(file_full_path)

    (state, modules_converted) = lexer_parse_convert_file(
        module_name,
        file_content,
        {"file": file_full_path, "compiling_module": True},
        bootstrap_prefix
    )

    case Elixir.Map.get(state, "error"):
        None ->
            # Child modules consist of structs, protocols, etc
            (child_modules, [parent_module]) = Elixir.Enum.split(modules_converted, -1)

            (child_modules, parent_module)
        _ ->
            Elixir.IO.puts("Compilation error:")
            Elixir.IO.puts("file path:")
            Elixir.IO.puts(file_full_path)

            {'error': {'pos_start': {'ln': line, 'col': col_start}, 'pos_end': {'col': col_end}, 'msg': msg}} = state
            meta = {
                "start": (None, line, col_start),
                "end": (None, line, col_end),
            }
            Exception.Code.format_error_in_source_code(file_content, meta)
                |> Elixir.IO.puts()
            Elixir.IO.puts(msg)

            raise "Compilation failed"

def save_module(module_name, file_full_path, compiled_folder, quoted):
    # Its super important to use this Module.create function
    # to ensure that our module binary will not have
    # Elixir. in the begin of the module name
    (_, _, binary, _) = Elixir.Module.create(
        Elixir.String.to_atom(module_name),
        quoted,
        [(:file, file_full_path)]
    )

    # we save .ex just to help debugging
    destine_ex = Elixir.Enum.join([compiled_folder, "/", module_name, ".ex"])
    destine_beam = Elixir.Enum.join([compiled_folder, "/", module_name, ".beam"])

    Elixir.File.write(destine_ex, Elixir.Macro.to_string(quoted))
    Elixir.File.write(destine_beam, binary, mode=:binary)

def lexer_parse_convert_file(module_name, text, config):
    lexer_parse_convert_file(module_name, text, config, None)

def lexer_parse_convert_file(module_name, text, config, bootstrap_prefix):
    # Main functions to lexer, parser and convert
    # Fython AST to Elixir AST

    compiling_module = Elixir.Map.get(config, "compiling_module", False)

    # 1º Lexer
    state = Core.Lexer.execute(text)

    # 2º Parser
    state = Core.Parser.execute(state['tokens'], text, config)

    # 3º Convert each node from Fython AST to Elixir AST
    ast = state['node'] |> add_prefix_to_function_calls(bootstrap_prefix)

    modules_converted = Core.Generator.Conversor.run_conversor(module_name, ast, text, config)

    (state, modules_converted)


def get_module_name(project_full_path, file_full_path):
    get_module_name(project_full_path, file_full_path, None)


def get_module_name(project_full_path, file_full_path, bootstrap_prefix):
    # input >
    #    project_full_path = /home/joao/fythonproject
    #    file_full_path = /home/joao/fythonproject/module/utils.fy
    # bootstrap_prefix
    #   Used in bootstraping. When we compile a module, they are loaded automaticly to current process.
    #   This can cause serious problems in bootstrap because the modules of current fython being compiled will
    #   start to be used to compile the next ones. We prevent this by compiling fython with a diferent prefix
    #   (that way the module will be loaded but will not replace the existing ones)
    #   and using this compiled to compile again, but this time without the prefix.
    # output > Module.Utils

    # if file name is __init__.fy
    # we wil remove this name and the module name passes to be
    # the name of this file parent folder

    case Elixir.String.starts_with?(file_full_path, project_full_path):
        True -> None
        False -> raise "File fullpath doent match project full path"

    project_parent_path = project_full_path
        |> Elixir.String.replace_suffix('/', '')
        |> Elixir.String.split('/')
        |> Elixir.Enum.slice(0..-2)
        |> Elixir.Enum.join('/')

    name = Elixir.String.replace_prefix(file_full_path, project_parent_path, "")

    # remove / from the start of the name
    name = case Elixir.String.graphemes(name) |> Elixir.Enum.at(0):
        "/" -> Elixir.String.graphemes(name) |> Elixir.Enum.slice(Elixir.Range.new(1, -1)) |> Elixir.Enum.join()
        _ -> name

    # remove .fy
    final = name
        |> Elixir.String.graphemes()
        |> Elixir.Enum.split(-3)
        |> Elixir.Kernel.elem(0)
        |> Elixir.Enum.join()
        |> Elixir.String.split("/")
        |> Elixir.Enum.map(lambda i: Elixir.String.capitalize(i))

    final = case Elixir.List.last(final):
        "__init__" ->
            final
                |> Elixir.List.pop_at(-1)
                |> Elixir.Kernel.elem(1)
                |> Elixir.Enum.join('.')
        _ -> final |> Elixir.Enum.join('.')

    case:
        bootstrap_prefix ->
            # Returns Fython.PREFIX.ModuleA.ModuleB
            Elixir.Enum.join([
                'Fython.',
                bootstrap_prefix,
                '.',
                Elixir.String.replace_prefix(final, 'Fython.', '')
            ])
        Elixir.String.starts_with?(final, 'Fython.') -> final
        True -> Elixir.Enum.join(['Fython.', final])

def add_prefix_to_function_calls(node, None):
    node

def add_prefix_to_function_calls(node, bootstrap_prefix):
    [node, state] = Core.Parser.Traverse.run(
        node, {"bootstrap_prefix": bootstrap_prefix}, &add_prefix/2
    )
    node


def add_prefix(node <- (:struct, meta, [struct_name, keywords]), state):
    {"bootstrap_prefix": bootstrap_prefix} = state

    struct_name = case Elixir.String.starts_with?(struct_name, 'Elixir.'):
        True -> struct_name
        False -> Elixir.Enum.join([bootstrap_prefix, '.', struct_name])

    [(:struct, meta, [struct_name, keywords]), state]

def add_prefix(node <- (:call, meta, [func_name, args, keywords, False]), state):
    {"bootstrap_prefix": bootstrap_prefix} = state

    (:var, var_meta, [var_pin, being_called]) = func_name

    being_called = case (Core.Parser.Utils.is_calling_function_of_fython_module(node), bootstrap_prefix):
        (False, _) -> being_called
        (True, '') -> being_called # no prefix
        (True, _) -> Elixir.Enum.join([bootstrap_prefix, '.', being_called])

    func_name = (:var, var_meta, [var_pin, being_called])

    [(:call, meta, [func_name, args, keywords, False]), state]

def add_prefix(node, state):
    [node, state]