package main

// mini-app: a WordPress stand-in. It reads settings from environment variables and talks to
// its database by *name* (DB_HOST), so it only works if Docker/Compose DNS resolves that name.
//   GET /        -> HTML page: title, env-driven settings, posts fetched from the database
//   POST /post   -> stores the request body as a new post in the database
//   GET /health  -> 200 if the database answers, 503 otherwise
import (
	"fmt"
	"html"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

func env(k, d string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return d
}

func main() {
	dbURL := fmt.Sprintf("http://%s:%s/rows", env("DB_HOST", "mini-db"), env("DB_PORT", "5432"))
	title := env("SITE_TITLE", "untitled site")
	client := &http.Client{Timeout: 3 * time.Second}

	posts := func() (string, error) {
		resp, err := client.Get(dbURL)
		if err != nil {
			return "", err
		}
		defer resp.Body.Close()
		b, _ := io.ReadAll(resp.Body)
		return string(b), nil
	}

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		if _, err := posts(); err != nil {
			http.Error(w, "db unreachable: "+err.Error(), 503)
			return
		}
		fmt.Fprintln(w, "ok")
	})
	http.HandleFunc("/post", func(w http.ResponseWriter, r *http.Request) {
		body, _ := io.ReadAll(io.LimitReader(r.Body, 4096))
		resp, err := client.Post(dbURL, "text/plain", strings.NewReader(string(body)))
		if err != nil {
			http.Error(w, "db unreachable: "+err.Error(), 503)
			return
		}
		resp.Body.Close()
		log.Printf("stored post %q via %s", string(body), dbURL)
		fmt.Fprintln(w, "post stored")
	})
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		log.Printf("%s \"%s %s\"", r.RemoteAddr, r.Method, r.URL.Path)
		p, err := posts()
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		fmt.Fprintf(w, "<h1>%s</h1><p>env: ENVIRONMENT=%s DB_HOST=%s</p>", html.EscapeString(title), html.EscapeString(env("ENVIRONMENT", "unset")), html.EscapeString(env("DB_HOST", "mini-db")))
		if err != nil {
			fmt.Fprintf(w, "<p style='color:red'>database error: %s</p>", html.EscapeString(err.Error()))
			return
		}
		fmt.Fprintf(w, "<pre>%s</pre>", html.EscapeString(p))
	})
	log.Printf("mini-app %q starting on :80, database at %s", title, dbURL)
	log.Fatal(http.ListenAndServe(":80", nil))
}
