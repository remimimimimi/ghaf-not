---
title: not-os
---

## boot

```
$ nix-build -A boot
@result@
```

The boot derivation creates a disk image with a FAT16 file system. It contains
the [kernel](kernel.html), the [initrd](initrd.html), and the [syslinux
configuration](syslinux.html).

It can be put in place in the complete, formatted [raw](raw.html) disk image
with `dd`.


### Note

The reason a FAT16 parition is used instead of an EXT4 partition (either the
same as the toplevel, or a dedicated boot partition), is that I didn't manage
to build a bootable EXT4 partition without using a root account (with `sudo`)
and mounting the image (with `losetup` and `mount`).

The only way I could find to install a bootloader without root and mount was to
use syslinux on a FAT16 parition.


<br />
@footer@
