---
title: not-os
---

## kernel

```
$ nix-build -A kernel
@result@
```

The kernel derivation results in an actual kernel, a bzImage file, but also in
a set of kernel modules.

The modules are packaged in the shrunk derivation, which itself is used to
create the initrd.


<br />
@footer@
