package main

import "fmt"

func a(int) int { return 7 }

func b(int) int { return 42 }

func main() {
	if x, y := a(1), b(2); x > 0 && x < y {
		fmt.Println("sometimes")
	}
	fmt.Println("always")
}
