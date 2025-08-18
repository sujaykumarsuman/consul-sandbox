package main

import (
	"fmt"
	"net/http"
	"os"
)

func main() {
	// Expect payload ID as a command-line argument
	if len(os.Args) < 2 {
		fmt.Println("Usage: ./hello-server <payload-id>")
		os.Exit(1)
	}
	payloadID := os.Args[1]
	port := "5050"

	http.HandleFunc("/hello", func(w http.ResponseWriter, r *http.Request) {
		response := fmt.Sprintf("Hello from hello-service in consul server: %s\n", payloadID)
		fmt.Fprint(w, response)
	})

	addr := fmt.Sprintf("0.0.0.0:%s", port)
	fmt.Printf("Starting hello-service on %s with cluster-id: %s...\n", addr, payloadID)
	err := http.ListenAndServe(addr, nil)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error starting server: %v\n", err)
		os.Exit(1)
	}
}
