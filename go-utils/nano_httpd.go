/*
  A Micro Lite Http File Server
  http://golang.org/pkg/net/http/#example_FileServer
  go build nano_httpd.go 
  ./nano_httpd --root="/home/ashish/ABLabs/AIAComponents"
*/
package main

import (
    "flag"
    "fmt"
	"log"
	"net/http"
)

func main() {
    inPort := flag.String("port","7070","Input Port Number, default 7070")
    flDir :=  flag.String("root", "~", "root content directory default is ~")
    flag.Parse()
     
    httpPort := ":" + *inPort
    fmt.Printf("Port %s, Doc Root [%s]\n",httpPort,*flDir)
     
	// Simple static webserver:
	log.Fatal(http.ListenAndServe(httpPort, http.FileServer(http.Dir(*flDir))))
}

