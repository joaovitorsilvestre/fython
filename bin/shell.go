package main;

import (
    "fmt"
    "os"
    "os/exec"
)

func check(e error) {
    if e != nil {
        panic(e)
    }
}

func main() {
    fmt.Println("starting fython shell")
    erl_path := "/tmp/fython-runtimer/erlang/lib/erlang/bin/erl"
    elixir_path := "/tmp/fython-runtimer/elixir/ebin"
    compiled := "/home/joao/fython/bin/_compiled"

    fmt.Println(erl_path, "-pa", compiled, "-pa", elixir_path, "-s", "Fython.Shell", "start", "-noshell")
    cmd := exec.Command(erl_path, "-pa", compiled, "-pa", elixir_path, "-s", "Fython.Shell", "start", "-noshell")

    // Sets standard output to cmd.stdout writer
    cmd.Stdout = os.Stdout

    // Sets standard input to cmd.stdin reader
    cmd.Stdin = os.Stdin

    err := cmd.Run()
    check(err)
}
