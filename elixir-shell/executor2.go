package main

import (
    "fmt"
    "io"
    "os/exec"
    "bufio"
    "os"
    "strings"
    "time"
)

// https://stackoverflow.com/questions/23166468/how-can-i-get-stdin-to-exec-cmd-in-golang
// https://stackoverflow.com/questions/31095699/return-cmd-stdout-and-stderr-as-string-instead-of-printing-to-console-in-golang

func main() {
    subProcess, reader, stdin, outbuf := GetProcess()

    fmt.Println("Simple Shell")
    fmt.Println("---------------------")

    for {
        fmt.Print("-> ")
        text, _ := reader.ReadString('\n')
        io.WriteString(stdin, text)
        time.Sleep(1 * time.Second)
        split := strings. Split(outbuf.String(), "iex")
        output := split[len(split)-2][5:]
        fmt.Println(output)
    }

    defer stdin.Close() // the doc says subProcess.Wait will close it, but I'm not sure, so I kept this line
    subProcess.Wait()
    fmt.Println("END") //for debug
}

func GetProcess() (*exec.Cmd, *bufio.Reader, io.WriteCloser, *strings.Builder) {
    subProcess := exec.Command("iex")

    outbuf := new(strings.Builder)
    errbuf := new(strings.Builder)
    subProcess.Stdout = outbuf
    subProcess.Stderr = errbuf

    stdin, err := subProcess.StdinPipe()
    if err != nil {
        fmt.Println(err) //replace with logger, or anything you want
    }

    fmt.Println("START") //for debug
    if err = subProcess.Start(); err != nil { //Use start, not run
        fmt.Println("An error occured: ", err) //replace with logger, or anything you want
    }

    reader := bufio.NewReader(os.Stdin)

    return subProcess, reader, stdin, outbuf
}

func ExecuteInElixir() {

}