package main;

import (
    "fmt"
    "os"
    "encoding/hex"
    "io/ioutil"
)

func check(e error) {
    if e != nil {
        panic(e)
    }
}

// https://medium.com/@skdomino/taring-untaring-files-in-go-6b07cf56bc07

func main() {
    fmt.Println("Hello, Worldss!")
    fmt.Println(len(os.Args), os.Args[1], os.Args[2])

    fython_runtimer_tar := os.Args[1]
    output_file_name := os.Args[2]

    fython_go_path := "./fython.go"

    bytes_tar_compiled, err := ioutil.ReadFile(fython_runtimer_tar)
    check(err)
    compiled_as_string := hex.EncodeToString(bytes_tar_compiled)

    fython_go, err := ioutil.ReadFile(fython_go_path)
    check(err)
    fython_go_content := string(fython_go)

    index_in_file_to_insert_hex := 475
    fmt.Println(fython_go_content[:index_in_file_to_insert_hex])

    final_file := fython_go_content[:index_in_file_to_insert_hex] + compiled_as_string + fython_go_content[index_in_file_to_insert_hex:]

    f, err := os.Create(output_file_name)
    check(err)
    defer f.Close()
    _, err = f.WriteString(final_file)
    check(err)
}
