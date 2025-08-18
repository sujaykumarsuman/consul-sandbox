package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
)

func main() {
	// Expect payload ID as a command-line argument
	if len(os.Args) < 3 {
		fmt.Println("Usage: ./hello-client <payload-id> <hello-service-address>")
		os.Exit(1)
	}
	payloadID := os.Args[1]
	helloService := os.Args[2]
	port := "8080"

	if helloService == "" {
		fmt.Println("HELLO_SERVICE_ADDRESS environment variable is required")
		os.Exit(1)
	}

	http.HandleFunc("/ping", func(w http.ResponseWriter, r *http.Request) {
		resp, err := http.Get(fmt.Sprintf("http://%s/hello", helloService))
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to call hello-server: %v", err), 500)
			return
		}
		defer resp.Body.Close()
		body, _ := io.ReadAll(resp.Body)
		fmt.Fprintf(w, "Response from hello-server with payload ID %s:\n%s", payloadID, body)
	})

	addr := fmt.Sprintf("0.0.0.0:%s", port)
	fmt.Println("Starting hello-client on :" + port + " with payload ID: " + payloadID)
	err := http.ListenAndServe(addr, nil)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error starting server: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("Hello client running on %s with payload ID: %s\n", addr, payloadID)
}
