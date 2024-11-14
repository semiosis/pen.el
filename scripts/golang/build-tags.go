///bin/true; exec /usr/bin/env go run "$0" "$@"

//go:build prod || dev || test

/* A build tag is a line comment starting with //go:build
and can be executed by go build -tags="foo bar" command.
Build tags are placed before the package clause near or at the top of the file followed by a blank line or other line comments.
It appears that gofmt automatically puts the build tags at the top.
Also, it appears that gofmt repects this form of 'shebang' line.
*/

// e:/volumes/home/shane/var/smulliga/source/git/adambard/learnxinyminutes-docs/go.html.markdown

package main

// Single line comment
/* Multi-
line comment */

/* A build tag is a line comment starting with //go:build
and can be executed by go build -tags="foo bar" command.
Build tags are placed before the package clause near or at the top of the file
followed by a blank line or other line comments. */

import (
	"fmt"
)

func main() {
	fmt.Println("Yo")
}
