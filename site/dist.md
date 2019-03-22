---
title: not-os
---

## dist

```
$ nix-build -A dist
@result@
```

The dist derivation creates a directory containing the kernel, the initrd, and
the rootfs.

It also contains a file with the kernel boot parameters.

In not-os, it contains the value for sysconfig (a path to toplevel), used in
the stage-1 init script to resolve the stage-2 init script.

Here, it is baked into stage-1. Doing so means that normally its closure is
increased (by the same dependencies of stage-2, i.e. the whole rootfs). But it
is possible to artificially remove a dependency with
`unsafeDiscardStringContext`.


<br />
@footer@
