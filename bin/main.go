package main;

import (
    "fmt"
    "os"
    "io"
    "path/filepath"
    "encoding/hex"
    "encoding/binary"
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
    b := "1f8b0800471e20620003edd03d0ac2401086e19134367a03753bad6456b2bb780acfb036a21003fef4f6dec02a57d18378036b5b13141104ad8208efd37cf0cd14c36471be1cce72a99396bc4fabb4c1e96bde3927361dd9aad66045ad06efc568ad573d6cd79bb832461679fcf8856ff33fd5db3765dc3553492ec746ab2c4ec57592b543f1dcd885e470eef465f0b31b0100000000000000000000000000ef6e567ad70000280000"
    data, err := hex.DecodeString(b)
    check(err)

    // salvando em um arquivo
    f, err := os.Create("file.tar.gz")
    check(err)
    defer f.Close()
    binary.Write(f, binary.LittleEndian, data)

    // lendo o arquivo
    dat, err := os.Open("file.tar.gz")
    err = Untar("/tmp", dat)
    check(err)

    if first == "build" {
        fmt.Println("build")
    } else if first == "shell" {
        fmt.Println("shell")
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