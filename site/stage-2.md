---
title: not-os
---

## stage-2

```
$ nix-build -A stage-2
@result@
```

stage-2 is a script defined as `config.system.build.bootStage2`. It is the
`init` script found in the rootfs, which is built as a squashfs image from
toplevel. See below.


<br />
@footer@
