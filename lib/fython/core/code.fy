def compile_project(project_path):
    compile_project(project_path, "_compiled", "")

def compile_project(project_path, destine, module_prefix):
    # start elixir compiler
    Erlang.application.start(:compiler)
    Erlang.application.start(:elixir)

    # If it's a absolute path we will not add the root as parent
    compiled_folder = case Elixir.String.starts_with?(destine, "/"):
        True -> destine
        False -> [project_path, destine] |> Elixir.Enum.join('/')

    # Ensure compiled folder is created
    Elixir.File.mkdir_p!(compiled_folder)

    # Ensure compiled folder is created
    Elixir.File.mkdir_p!(compiled_folder)

    files = [project_path, "**/*.fy"]
        |> Elixir.Enum.join('/')
        |> Elixir.Path.wildcard()

    compile_files(project_path, files, compiled_folder, module_prefix)

def compile_files(project_path, files, compiled_folder, module_prefix):
    # files: [a.fy, folder/b.fy, etc]

    modules_ready_to_be_saved = files
        |> Elixir.Enum.map(lambda file:
            (child_modules, parent_module) = pre_compile_file(project_path, file, module_prefix)
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


def pre_compile_file(project_root, file_full_path, module_prefix):
    module_name = get_module_name(project_root, file_full_path, module_prefix)

    Elixir.IO.puts(Elixir.Enum.join(["Compiling module: ", module_name]))

    (:ok, file_content) = Elixir.File.read(file_full_path)

    (state, modules_converted) = lexer_parse_convert_file(
        module_name,
        file_content,
        {"file": file_full_path, "compiling_module": True}
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
            text = Elixir.File.read(file_full_path) |> Elixir.Kernel.elem(1)
            Core.Errors.Utils.print_error(module_name, state, text)
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
    # Main functions to lexer, parser and convert
    # Fython AST to Elixir AST

    lexed = Core.Lexer.execute(text)

    # 1º Convert each node from Fython AST to Elixir AST
    state = case Elixir.Map.get(lexed, "error"):
        None ->
            tokens = Elixir.Map.get(lexed, "tokens")
            Core.Parser.execute(tokens, config)
        _ ->
            lexed

    state_error = Elixir.Map.get(state, 'error')
    compiling_module = Elixir.Map.get(config, "compiling_module", False)

    # 2º Convert each node from Fython AST to Elixir AST
    case Elixir.Map.get(state, 'error'):
        None ->
            ast = state['node']
            modules_converted = Core.Generator.Conversor.run_conversor(module_name, ast, text, config)

            (state, modules_converted)
        _ -> (state, None)


def get_module_name(project_full_path, file_full_path):
    get_module_name(project_full_path, file_full_path, "")


def get_module_name(project_full_path, file_full_path, module_prefix):
    # input >
    #    project_full_path = /home/joao/fythonproject
    #    file_full_path = /home/joao/fythonproject/module/utils.fy
    # module_prefix
    #   usefull for bootstraping. When we compile a module, they are loaded automaticly to current process.
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
    name = Elixir.Enum.join([module_prefix, name])

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

    Elixir.Enum.join(["Fython.", final])
