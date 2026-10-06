package main

// mini-web: a tiny static web server (nginx stand-in) that logs every request to stdout.
import (
	"log"
	"net/http"
	"os"
)

func main() {
	root := os.Getenv("WEB_ROOT")
	if root == "" {
		root = "/www"
	}
	port := os.Getenv("PORT")
	if port == "" {
		port = "80"
	}
	fs := http.FileServer(http.Dir(root))
	http.Handle("/", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Printf("%s \"%s %s %s\" %q", r.RemoteAddr, r.Method, r.URL.Path, r.Proto, r.UserAgent())
		fs.ServeHTTP(w, r)
	}))
	log.Printf("mini-web serving %s on :%s", root, port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
