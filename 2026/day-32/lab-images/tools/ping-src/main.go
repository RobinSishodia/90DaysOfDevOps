package main

// mini-ping: a minimal ICMP echo client (the ubuntu-mini image has no ping binary).
// Usage: ping [-c count] <host-or-ip>   (needs CAP_NET_RAW, which Docker grants by default)
import (
	"fmt"
	"net"
	"os"
	"strconv"
	"time"
)

func checksum(b []byte) uint16 {
	var s uint32
	for i := 0; i+1 < len(b); i += 2 {
		s += uint32(b[i])<<8 | uint32(b[i+1])
	}
	if len(b)%2 == 1 {
		s += uint32(b[len(b)-1]) << 8
	}
	for s>>16 > 0 {
		s = (s & 0xffff) + s>>16
	}
	return ^uint16(s)
}

func main() {
	count := 3
	args := os.Args[1:]
	if len(args) >= 2 && args[0] == "-c" {
		count, _ = strconv.Atoi(args[1])
		args = args[2:]
	}
	if len(args) != 1 {
		fmt.Println("usage: ping [-c count] <host>")
		os.Exit(2)
	}
	host := args[0]
	ips, err := net.LookupIP(host)
	if err != nil || len(ips) == 0 {
		fmt.Printf("ping: %s: Name or service not known\n", host)
		os.Exit(2)
	}
	var ip net.IP
	for _, c := range ips {
		if c.To4() != nil {
			ip = c
			break
		}
	}
	if ip == nil {
		fmt.Printf("ping: %s: no IPv4 address\n", host)
		os.Exit(2)
	}
	conn, err := net.DialIP("ip4:icmp", nil, &net.IPAddr{IP: ip})
	if err != nil {
		fmt.Printf("ping: socket: %v\n", err)
		os.Exit(2)
	}
	defer conn.Close()
	fmt.Printf("PING %s (%s): 8 data bytes\n", host, ip)
	recv := 0
	id := os.Getpid() & 0xffff
	for seq := 1; seq <= count; seq++ {
		msg := []byte{8, 0, 0, 0, byte(id >> 8), byte(id), byte(seq >> 8), byte(seq), 'd', 'e', 'v', 'o', 'p', 's', '9', '0'}
		cs := checksum(msg)
		msg[2], msg[3] = byte(cs>>8), byte(cs)
		start := time.Now()
		conn.SetDeadline(time.Now().Add(2 * time.Second))
		if _, err := conn.Write(msg); err != nil {
			fmt.Printf("ping: write: %v\n", err)
			continue
		}
		buf := make([]byte, 512)
		ok := false
		for {
			n, err := conn.Read(buf)
			if err != nil {
				break
			}
			// raw ip4 reads include the IP header
			ihl := int(buf[0]&0x0f) * 4
			if n > ihl+7 && buf[ihl] == 0 && int(buf[ihl+6])<<8|int(buf[ihl+7]) == seq {
				fmt.Printf("%d bytes from %s: icmp_seq=%d ttl=%d time=%.3f ms\n", n-ihl, ip, seq, buf[8], float64(time.Since(start).Microseconds())/1000)
				ok = true
				recv++
				break
			}
		}
		if !ok {
			fmt.Printf("Request timeout for icmp_seq %d\n", seq)
		}
		time.Sleep(300 * time.Millisecond)
	}
	fmt.Printf("--- %s ping statistics ---\n%d packets transmitted, %d received, %d%% packet loss\n", host, count, recv, (count-recv)*100/count)
	if recv == 0 {
		os.Exit(1)
	}
}
