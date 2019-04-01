---
title: not-os
---

## TODO

(By page, I mean a .md file in this directory.)

- digitalocean page with explanation of how to upload the qcow2 image (gzipped)
  then create a droplet (using doctl).

- note somewhere this: if an attribute build causes this error

```
cp: cannot create regular file '/nix/store/dgv0n0k4a43xz5bwfwvdmvgfn46ksc94-all/ext4.md': Permission denied
```

  this can be caused by creating (with `cp`) twice the same file in `$out`.
