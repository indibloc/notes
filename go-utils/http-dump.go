/*
 Dump http request
*/
package main

import (
    "flag"
    "fmt"
	"log"
	"net/http"
	u "net/http/httputil"
)

type dumpHandler struct {
}

func main() {
    inPort := flag.String("port","6060","Input Port Number, default 6060")
    flag.Parse()
     
    httpPort := ":" + *inPort
    fmt.Printf("Port %s, Will Dump the Request \n",httpPort)
     
	// Dump:
	log.Fatal(http.ListenAndServe(httpPort, &dumpHandler{}))
}

func (h *dumpHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	b, err := u.DumpRequest(r,true)
	w.Header().Set("Content-Type", "text/plain; charset=utf-8") // normal header
	if err != nil {
	    w.WriteHeader(http.StatusInternalServerError)
	    w.Write([]byte(err.Error()))
	} else {
	   w.WriteHeader(http.StatusOK)
       w.Write(b)
       w.Write([]byte("\nRemote Address:["+ r.RemoteAddr+"]\n"))
	}
	
}
