///bin/true; exec /usr/bin/env go run "$0" "$@"

package main

import (
	"bytes"
	"io"
	"os"
	"os/exec"
)

func main() {
	stdin, err := io.ReadAll(os.Stdin)

	if err != nil {
		panic(err)
	}
	str := string(stdin)

	// fmt.Println(strings.TrimSuffix(str, "\n"))

	tv(str)
}

func tv(mystdin string) (string, string) {
	if len(mystdin) == 0 {
		return "", ""
	}

	subProcess := exec.Command("tv")
	stdin, _ := subProcess.StdinPipe()
	defer stdin.Close()

	cmdOutput := &bytes.Buffer{}
	subProcess.Stdout = cmdOutput

	cmdError := &bytes.Buffer{}
	subProcess.Stderr = cmdError

	subProcess.Start()
	io.WriteString(stdin, mystdin)
	stdin.Close()
	subProcess.Wait()

	r_out := cmdOutput.String()
	r_error := cmdError.String()
	return r_out, r_error
}
