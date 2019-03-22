---
title: not-os
---

## extra-utils

```
$ nix-build -A extra-utils
@result@
```

extra-utils is a derivation packaging busybox, dhcpd, and their required
libraries. They are modified using `patchelf` so the content of the derivation
is self-sufficient.

It is packaged with the stage-1 init script to create the initrd; it is
everything the stage-1 init script can use to do its job.


<br />
@footer@
