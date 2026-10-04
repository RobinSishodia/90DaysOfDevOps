#!/usr/bin/env python3
"""minidig: a tiny 'dig' replacement (A/AAAA/CNAME/MX/NS) that shows TTLs.
Usage: minidig.py <name> [TYPE] [server]"""
import random, socket, struct, sys

TYPES = {"A": 1, "NS": 2, "CNAME": 5, "MX": 15, "AAAA": 28}
NAMES = {v: k for k, v in TYPES.items()}

def read_name(msg, off):
    labels, jumped, end = [], False, off
    while True:
        n = msg[off]
        if n & 0xC0 == 0xC0:
            if not jumped:
                end = off + 2
            off = struct.unpack("!H", msg[off:off + 2])[0] & 0x3FFF
            jumped = True
            continue
        if n == 0:
            off += 1
            break
        labels.append(msg[off + 1:off + 1 + n].decode())
        off += 1 + n
    return ".".join(labels) + ".", (end if jumped else off)

def query(name, qtype="A", server="8.8.8.8"):
    tid = random.randint(0, 65535)
    q = struct.pack("!HHHHHH", tid, 0x0100, 1, 0, 0, 0)
    q += b"".join(bytes([len(p)]) + p.encode() for p in name.strip(".").split(".")) + b"\0"
    q += struct.pack("!HH", TYPES[qtype], 1)
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(3)
    s.sendto(q, (server, 53))
    msg, _ = s.recvfrom(4096)
    _, flags, qd, an, _, _ = struct.unpack("!HHHHHH", msg[:12])
    off = 12
    for _ in range(qd):
        _, off = read_name(msg, off)
        off += 4
    print(f";; SERVER: {server}#53  status: {'NOERROR' if flags & 0xF == 0 else 'ERROR'}  answers: {an}")
    print(";; ANSWER SECTION:")
    for _ in range(an):
        rname, off = read_name(msg, off)
        rtype, _, ttl, rdlen = struct.unpack("!HHIH", msg[off:off + 10])
        off += 10
        rdata = msg[off:off + rdlen]
        if rtype == 1:
            val = socket.inet_ntoa(rdata)
        elif rtype == 28:
            val = socket.inet_ntop(socket.AF_INET6, rdata)
        elif rtype in (2, 5):
            val = read_name(msg, off)[0]
        elif rtype == 15:
            val = f"{struct.unpack('!H', rdata[:2])[0]} {read_name(msg, off + 2)[0]}"
        else:
            val = rdata.hex()
        off += rdlen
        print(f"{rname:<22} {ttl:<6} IN {NAMES.get(rtype, rtype):<6} {val}")

if __name__ == "__main__":
    query(sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else "A").upper(),
          sys.argv[3] if len(sys.argv) > 3 else "8.8.8.8")
