---
title: not-os
---

## shrunk

```
$ nix-build -A shrunk
@result@
```

This is a subset of the module tree produced in the kernel derivation. The
subset is specified by the `rootModules` argument in stage-1.nix.

That subset is packaged as part of the initrd.

The lis of modules can be extracted with:

```
$ nix-instantiate --eval --strict -A root-modules
```


<br />
@footer@
