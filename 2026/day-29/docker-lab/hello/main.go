package main

import (
	"fmt"
	"os"
)

func main() {
	host, _ := os.Hostname()
	fmt.Println("Hello from Docker! (robin/hello - built FROM scratch)")
	fmt.Println("")
	fmt.Println("To generate this message, Docker took the following steps:")
	fmt.Println(" 1. The Docker client contacted the Docker daemon.")
	fmt.Println(" 2. The daemon found the image robin/hello locally (I built it - no registry needed).")
	fmt.Println(" 3. The daemon created a new container from that image and ran this program.")
	fmt.Println(" 4. The daemon streamed this output back to the Docker client, which printed it.")
	fmt.Println("")
	fmt.Printf("Container hostname (= short container ID): %s\n", host)
}
