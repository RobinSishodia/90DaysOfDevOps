# Day 02 – How Linux Works: Kernel, Processes and systemd

> Commands run on a cloud Ubuntu 24.04 practice VM (kernel 6.18).

## Core components
- **Kernel**: controls the CPU, memory, devices, file systems and networking. It's the only layer that talks to the hardware.
- **User space**: shells, apps and tools (bash, python, nginx). These programs ask the kernel for things through **system calls** (`open`, `read`, `fork`, `exec`).
- **init / systemd**: the first user-space process (**PID 1**). It starts and supervises every other service.

## Boot flow
BIOS/UEFI → bootloader (GRUB) → kernel → PID 1 (systemd) → services and targets

## How processes are created
- A **program** is a file on disk. A **process** is that program running, with a PID and a PPID (parent PID).
- `fork()` copies the parent, then `exec()` swaps in the new program.
- If a parent dies first, its orphaned children are adopted by PID 1.

## Process states
| Code | State | Meaning |
|---|---|---|
| R | Running | On the CPU, or ready to run |
| S | Sleeping | Waiting for an event. Most processes are in this state. |
| D | Uninterruptible sleep | Stuck waiting on disk or I/O and can't be killed |
| T | Stopped | Paused (Ctrl+Z / SIGSTOP) |
| Z | Zombie | Finished, but the parent hasn't collected its exit code yet |
| I | Idle | Idle kernel thread |

## What I saw on my VM
```
$ ps -o pid,ppid,stat,comm -p 1,2,260
  PID  PPID STAT COMMAND
    1     0 SLl  process_api
    2     0 S    kthreadd
  260     1 S    python3

$ ps -eo stat | cut -c1 | sort | uniq -c
     31 I
      3 R
     33 S

$ systemctl status cron
System has not been booted with systemd as init system (PID 1). Can't operate.
```
**Lesson learned:** PID 1 here is **not** systemd. This VM is a lightweight microVM with its own init (`process_api`), so `systemctl` can't run. That's common in containers and minimal VMs, so checking PID 1 is a good first step on any new box. Most processes were sleeping (S) or idle kernel threads (I), and there were no zombies.

## Why systemd matters
- Starts services at boot in the right order, and restarts them if they crash (`Restart=on-failure`).
- `systemctl status|start|stop|restart|enable <svc>` manages services.
- `journalctl -u <svc>` reads a service's logs.

## 5 commands I'd use daily
1. `ps aux` – list all processes
2. `top` – watch CPU and memory live
3. `systemctl status <svc>` – check a service's health
4. `journalctl -u <svc> -f` – follow a service's logs
5. `kill <PID>` – stop a process (`-9` only as a last resort)
