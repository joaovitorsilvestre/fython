def test_regex():
    assert Elixir.Regex.replace(r"^hi,", "hi, tudo bem?", "hello,") == "hello, tudo bem?"
    assert Elixir.Regex.regex?(r"regex")

    (:ok, compiled) = Elixir.Regex.compile("^text$")
    assert compiled == r"^text$"