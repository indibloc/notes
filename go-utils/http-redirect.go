/*
 Redirect http request
*/
package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"strings"
	//u "net/http/httputil"
)

type redirectHandler struct {
	url string
}

func main() {
	inPort := flag.String("port", "80", "Input Port Number, default 80")
	redirect := flag.String("url", "www.qzip.in", "Redirect to site, default, www.qzip.in")
	flag.Parse()

	httpPort := ":" + *inPort

	handler := redirectHandler{url: *redirect}
	fmt.Printf("Port %s,\n Redirect URL %s \n", httpPort, handler.url)

	// Dump:
	log.Fatal(http.ListenAndServe(httpPort, &handler))
}

var html string = `<html>   
  <head>
    <meta http-equiv="Refresh" content="1; url=http://www.innomon.in"> 
  </head>
  <body>
    <h1>Redirecting to WWW</h1>
    Automatic redirecting to <a href="www.innomon.in"> www.innomon.in</a><br/>
  </body>
</html>
`

func (h *redirectHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Header().Set("Location", "http://www.qzip.in")

	w.WriteHeader(http.StatusMovedPermanently)
	w.Write([]byte(strings.Replace(html, "www.innomon.in", h.url, -1)))

}
