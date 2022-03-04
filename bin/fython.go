package main;

import (
    "fmt"
    "os"
    "bytes"
    "os/exec"
    "io"
    "path/filepath"
    "encoding/hex"
    "archive/tar"
    "compress/gzip"
)

func check(e error) {
    if e != nil {
        panic(e)
    }
}

// https://medium.com/@skdomino/taring-untaring-files-in-go-6b07cf56bc07

func main() {
    fmt.Println("Hello, Worldss!")
    fmt.Println(len(os.Args), os.Args[1])

    first := os.Args[1]

    // hex do tar.gz
    b := ""
    data, err := hex.DecodeString(b)
    check(err)

    // lendo o arquivo
    reader := bytes.NewReader(data)
    err = Untar("/tmp", reader)
    check(err)

    if first == "build" {
        fmt.Println("build")
    } else if first == "shell" {
        fmt.Println("starting fython shell")
        erl_path := "/tmp/fython-runtimer/erlang/lib/erlang/bin/erl"
        elixir_path := "/tmp/fython-runtimer/elixir/ebin"

        cmd := exec.Command(erl_path, "-pa", os.Args[2], "-pa", elixir_path, "-s", "'Fython.Shell'", "start", "-noshell")

        // Sets standard output to cmd.stdout writer
        cmd.Stdout = os.Stdout

        // Sets standard input to cmd.stdin reader
        cmd.Stdin = os.Stdin

        err = cmd.Run()
        check(err)
    }
}

func Untar(dst string, r io.Reader) error {
	gzr, err := gzip.NewReader(r)
	if err != nil {
		return err
	}
	defer gzr.Close()

	tr := tar.NewReader(gzr)

	for {
		header, err := tr.Next()

		switch {

		// if no more files are found return
		case err == io.EOF:
			return nil

		// return any other error
		case err != nil:
			return err

		// if the header is nil, just skip it (not sure how this happens)
		case header == nil:
			continue
		}

		// the target location where the dir/file should be created
		target := filepath.Join(dst, header.Name)

		// the following switch could also be done using fi.Mode(), not sure if there
		// a benefit of using one vs. the other.
		// fi := header.FileInfo()

		// check the file type
		switch header.Typeflag {

		// if its a dir and it doesn't exist create it
		case tar.TypeDir:
			if _, err := os.Stat(target); err != nil {
				if err := os.MkdirAll(target, 0755); err != nil {
					return err
				}
			}

		// if it's a file create it
		case tar.TypeReg:
			f, err := os.OpenFile(target, os.O_CREATE|os.O_RDWR, os.FileMode(header.Mode))
			if err != nil {
				return err
			}

			// copy over contents
			if _, err := io.Copy(f, tr); err != nil {
				return err
			}

			// manually close here after each file operation; defering would cause each file close
			// to wait until all operations have completed.
			f.Close()
		}
	}
}