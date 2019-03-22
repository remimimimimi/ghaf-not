---
title: not-os
---

## path

```
$ nix-build -A path
@result@
```

While extra-utils provides a set of symlinks pointing to busybox to the stage-1
script, path provides a set of symlinks pointing to various executables in the
Nix store to the stage-2 script.

path is defined in the `system-path.nix` module.


<br />
@footer@
