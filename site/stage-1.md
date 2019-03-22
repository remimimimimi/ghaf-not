---
title: not-os
---

## stage-1

```
$ nix-build -A stage-1
@result@
```

stage-1 is a script defined as `config.system.build.bootStage1`. It is the
content of the initrd.

TODO Describe stage-1.

It prepares the Nix store (at `/mnt/nix/store`, which will be at `/nix/store`
once `switch_root` is performed).

The final action of stage-1 is to call `switch_root` (using `/mnt` as the new
root) to execute stage-2.

In vpsadminos, the stage-1 exists as a script, `stage-1-init.sh` (just like
`stage-2-init.sh`). It contains code testing a possible `nolive` flag, and thus
the two branches of the `if` statement.

In not-os, the flag is defined at build time so the generated script contains
only the desired code. Similarly, the `overlay` kernel module is loaded only if
necessay. The resulting script is less flexible but I like the idea of
generating exactly what we decide.


<br />
@footer@
