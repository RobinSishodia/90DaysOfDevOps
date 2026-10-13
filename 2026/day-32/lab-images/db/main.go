package main

// mini-db: a tiny stand-in for MySQL/Postgres. It keeps its "data directory" at $DATA_DIR
// (default /data) as an append-only file, so whether data survives depends only on whether
// /data is a volume. HTTP API:  POST /rows (body = text)  |  GET /rows  |  GET /health
import (
	"bufio"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"sync"
	"time"
)

func main() {
	dir := os.Getenv("DATA_DIR")
	if dir == "" {
		dir = "/data"
	}
	port := os.Getenv("PORT")
	if port == "" {
		port = "5432"
	}
	if err := os.MkdirAll(dir, 0o755); err != nil {
		log.Fatal(err)
	}
	file := filepath.Join(dir, "rows.txt")
	var mu sync.Mutex

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) { fmt.Fprintln(w, "ok") })
	http.HandleFunc("/rows", func(w http.ResponseWriter, r *http.Request) {
		mu.Lock()
		defer mu.Unlock()
		switch r.Method {
		case http.MethodPost:
			body, _ := io.ReadAll(io.LimitReader(r.Body, 4096))
			f, err := os.OpenFile(file, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
			if err != nil {
				http.Error(w, err.Error(), 500)
				return
			}
			defer f.Close()
			fmt.Fprintf(f, "%s\t%s\n", time.Now().Format("15:04:05"), string(body))
			log.Printf("INSERT %q from %s", string(body), r.RemoteAddr)
			fmt.Fprintln(w, "inserted")
		default:
			f, err := os.Open(file)
			if err != nil {
				return // no rows yet: empty response
			}
			defer f.Close()
			sc := bufio.NewScanner(f)
			n := 0
			for sc.Scan() {
				n++
				fmt.Fprintf(w, "%d\t%s\n", n, sc.Text())
			}
			log.Printf("SELECT -> %d rows to %s", n, r.RemoteAddr)
		}
	})
	log.Printf("mini-db ready, data dir %s, listening on :%s", dir, port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
