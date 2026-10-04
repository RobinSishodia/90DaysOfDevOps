# Day 13 – Linux Volume Management (LVM) & Extending Storage

> Practice VM: Ubuntu 24.04 cloud microVM, run as root. Output is shown as text instead of screenshots.

## ⚠️ What happened
**The LVM tools weren't installed** on my practice VM, and package downloads are blocked there:
```
$ pvs
pvs: command not found
```
So I practised the **same storage workflow** (virtual disk → format → mount → extend by 200M) with a loop device and ext4. The LVM version is written out below so I can run it on an EC2 instance with an extra EBS volume.

## 1. Storage assessment
```
$ lsblk -o NAME,SIZE,TYPE,MOUNTPOINTS | grep -E 'NAME|loop|vda '
NAME    SIZE TYPE MOUNTPOINTS
loop0     1G loop                ← leftover from an earlier test
vda     256G disk /

$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G   15G   30G  34% /
```

## 2. Virtual disk (`dd` + `losetup`)
```
$ dd if=/dev/zero of=/root/devops-disk.img bs=1M count=500 status=none && ls -lh /root/devops-disk.img
-rw-r--r-- 1 root root 500M Oct  4 19:16 /root/devops-disk.img

$ losetup -fP --show /root/devops-disk.img
/dev/loop0
$ losetup -l | grep devops
/dev/loop0         0      0         0  0 /root/devops-disk.img   0     512
```

## 3. Format and mount
```
$ mkfs.ext4 -q -L app-data /dev/loop0 && blkid /dev/loop0
/dev/loop0: LABEL="app-data" UUID="72780ec5-6929-461e-ad1b-0439378a86b2" BLOCK_SIZE="4096" TYPE="ext4"

$ mkdir -p /mnt/app-data && mount /dev/loop0 /mnt/app-data && df -h /mnt/app-data
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0      452M   24K  417M   1% /mnt/app-data

$ echo 'app config v1' > /mnt/app-data/config.txt
```
The 500M disk shows **452M** usable, because ext4 reserves space for its own metadata and journal.

## 4. Extend by 200M
```
$ truncate -s +200M /root/devops-disk.img && losetup -c /dev/loop0 && lsblk -o NAME,SIZE /dev/loop0
NAME   SIZE
loop0  700M                              ← the disk grew...

$ df -h /mnt/app-data
/dev/loop0      452M   28K  417M   1% /mnt/app-data    ← ...but the filesystem didn't

$ resize2fs /dev/loop0
resize2fs: Permission denied to resize filesystem
Filesystem at /dev/loop0 is mounted on /mnt/app-data; on-line resizing required
```
**Online resize was blocked** by the VM's sandbox, so I resized it **offline**:
```
$ umount /mnt/app-data
$ e2fsck -f -p /dev/loop0
app-data: 12/128000 files (0.0% non-contiguous), 12303/128000 blocks
$ resize2fs /dev/loop0
Resizing the filesystem on /dev/loop0 to 179200 (4k) blocks.
The filesystem on /dev/loop0 is now 179200 (4k) blocks long.

$ mount /dev/loop0 /mnt/app-data && df -h /mnt/app-data
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0      637M   28K  588M   1% /mnt/app-data    ← 452M → 637M ✅
$ cat /mnt/app-data/config.txt
app config v1                                           ← data survived ✅
```

## The LVM version (to run on EC2)
```bash
sudo apt install -y lvm2
lsblk; pvs; vgs; lvs; df -h
sudo pvcreate /dev/xvdf                      # or a loop device
sudo vgcreate devops-vg /dev/xvdf
sudo lvcreate -L 500M -n app-data devops-vg
sudo mkfs.ext4 /dev/devops-vg/app-data
sudo mkdir -p /mnt/app-data && sudo mount /dev/devops-vg/app-data /mnt/app-data
sudo lvextend -L +200M /dev/devops-vg/app-data
sudo resize2fs /dev/devops-vg/app-data       # or: lvextend -r (resize in one step)
df -h /mnt/app-data
```
**The layers:** disk → **PV** (physical volume) → **VG** (a pool of storage) → **LV** (a flexible "partition") → filesystem → mount point

## What I learned (3 points)
1. **Growing storage takes two steps: grow the device, then grow the filesystem.** `lsblk` showed 700M, but `df` still showed 452M until I ran `resize2fs`.
2. **ext4 can grow while mounted, but some environments block it.** The offline route is `umount` → `e2fsck -f` → `resize2fs` → `mount`, which means downtime. That's one reason production uses LVM, so you can run `lvextend -r` with no downtime.
3. **LVM makes storage flexible.** You can pool several disks into one volume group and resize logical volumes without repartitioning.
