def install_package_from_url(project_folder, package_name, url):
    # Usage:
    # 'Fython.Fy':install_package_from_url(
    #    "/home/joao/fython/fy", "jason", "https://github.com/michalmuskala/jason/archive/v1.2.1.zip"
    #  ).

    destine_folder = Elixir.Enum.join(["/tmp/", package_name])

    (:ok, source_path) = download_package_source(url)

    deps_folder = Elixir.Enum.join([project_folder, "/", "_deps"])
    Elixir.File.mkdir_p!(deps_folder)

    (:ok, _) = compile_package(source_path, deps_folder)

def compile_package(source_path, destine_folder):
    files = [source_path, "*/lib/**/*.ex"]
        |> Elixir.Enum.join('/')
        |> Elixir.Path.wildcard()

    Elixir.IO.inspect([source_path, "*/lib/**/*.ex"] |> Elixir.Enum.join('/'))

    Elixir.Kernel.ParallelCompiler.compile_to_path(files, destine_folder, [])
    (:ok, destine_folder)

def download_package_source(url):
    Erlang.application.ensure_all_started(:inets)
    Erlang.application.ensure_all_started(:ssl)

    url = Elixir.Kernel.to_charlist(url)

    (:ok, ((_, 200, _), _headers, body)) = Erlang.httpc.request(:get, (url, []), [], [])

    zip_temp = Elixir.Enum.join([
        "/tmp/",
        Elixir.Kernel.to_string(url)
            |> Elixir.String.replace("/", "_")
            |> Elixir.String.replace(':', '_')
            |> Elixir.String.replace(':', '_')
            |> Elixir.String.replace('.', '_')
    ])

    zipped_path = Elixir.Enum.join([zip_temp, ".zip"])
    extracted_path = Elixir.Enum.join([zip_temp, "_extracted"])

    # TODO delete .zip

    Elixir.File.write!(zipped_path, body, mode=:binary)
    Erlang.zip.unzip(
        Elixir.Kernel.to_charlist(zipped_path),
        [(:cwd, Elixir.Kernel.to_charlist(extracted_path))]
    )
    (:ok, extracted_path)
