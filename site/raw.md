---
title: not-os
---

## raw

```
$ nix-build -A raw
@result@
```

The raw derivation creates a bootable disk image. It contains a [FAT16 boot
partition](boot.html) and an [EXT4 toplevel](ext4.html) partition.

To explore the result, we can use `sfdisk` and mount the disk as follow:

First, let's find the offset of the two partitions within the image:

```
$ sfdisk -l result
Disk result: 296.7 MiB, 311046144 bytes, 607512 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x20000000

Device     Boot Start    End Sectors   Size Id Type
result1    *     2048  22527   20480    10M  b W95 FAT32
result2         22528 607511  584984 285.7M 83 Linux
```

Then mount the boot partition with the correct offset:

```
$ mkdir tmp
$ sudo mount -o offset=$((2048 * 512)) result tmp
$ ls tmp/
initrd  ldlinux.c32  ldlinux.sys  syslinux.cfg  vmlinuz
```

Or the main partition (use `umount tmp` to unmount the boot partition):

```
$ sudo mount -o offset=$((22528 * 512)) result tmp
$ ls tmp/
lost+found  nix  nix-path-registration
```

An alternative way to mount the partitions is to use `losetup`:

```
$ sudo losetup --show -f -P result
/dev/loop0
$ sudo mount /dev/loop0p1 tmp
```

You can replace `loop0p1` by `loop0p2` to mount the EXT4 partition instead. Use
`sudo losetup -d /dev/loop0` after unmounting to detach the loop device.

Another useful tool is `blkid`:

```
$ blkid result
result: PTUUID="20000000" PTTYPE="dos"
```

To display the other partition:

```
$ blkid --probe --offset $((22528 * 512)) result
result: LABEL="TOPLEVEL" UUID="44444444-4444-4444-8888-888888888888" VERSION="1.0" TYPE="ext4" USAGE="filesystem"
```

### Note

The raw image (or the derived qcow2 image) doesn't work on Digital Ocean. See
[this page](digital-ocean.html) for an explanation and a work-around.


<br />
@footer@
