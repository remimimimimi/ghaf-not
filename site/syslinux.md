---
title: not-os
---

## syslinux

```
$ nix-build -A syslinux
@result@
```

This attribute builds the `syslinux.cfg` file used to configure the syslinux
bootloader. The file is put on the FAT16 [boot](boot.html) partition.


<br />
@footer@
