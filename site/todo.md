---
title: not-os
---

## TODO

- digitalocean page with explanation of how to upload the qcow2 image (gzipped)
  then create a droplet (using doctl).

- On Digital Ocean, use the public SSH key provided in the config-2 disk.

- note somewhere this: if an attribute build causes this error

```
cp: cannot create regular file '/nix/store/dgv0n0k4a43xz5bwfwvdmvgfn46ksc94-all/ext4.md': Permission denied
```

  this can be caused by creating (with `cp`) twice the same file in `$out`.


Help would be appreciated for a few things:

- Create a bootable EXT4 partition without using root privilege or mount.
  This would allow to create an image running on Digital Ocean with a normal
Nix attribute instead of the special make-qcow2.sh script.

- Allow to reference the site derivation directly within the image definition.
  I didn't manage to do it because this creates a recursive definition (the
image depends on the site which use the image result paths to embed them in the
documentation). Currently I'm using an impure `/var/www` path to break the
cycle.

- Support S6 in addition of runit.

- Try to reuse the Nginx NixOS module to craft its configuration. The problem
  is that NixOS modules assume a lot (e.g. systemd units).

- There is a lot of repetition in `site/default.nix`.

- Creating the actual HTML pages is done out of this repository. I'd like to
  generate them directly here, possibly with a DocBook toolchain.
