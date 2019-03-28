---
title: not-os
---

## rootfs

```
$ nix-build -A rootfs
@result@
```

The rootf derivation, defined as `config.system.build.squashfs`, creates a
squashfs image. It contains the closures of toplevel and a registration file.

To explore the result, we can extract the content of the rootfs in a temporary
directory as follow:

```
$ mkdir tmp ; cd tmp
$ unsquashfs $(readlink -fn ../result)
$ find -maxdepth 2
.
./squashfs-root
./squashfs-root/5f18ah2yzyf4mmnn8jqqb7aws91rw55v-ssh_host_rsa_key.pub
./squashfs-root/wqfpawgsigwnz2bk1ygkfya7802jxl9c-iputils-20180629
./squashfs-root/p54mjqlrngzzyb2892489b4hffgz03g2-aws-sdk-cpp-1.5.17
./squashfs-root/jaiq6xgyhhl84826lrsxbgdy5sm9n8wx-nixos.conf
...
```

The derivation is defined as a call to `nixpkgs/nixos/lib/make-squashfs.nix`,
passing toplevel as argument. The closure is constructed by
`nixpkgs/build-support/closure-info.nix`.

A call to `nix-store --load-db` with the registration file found in the rootfs
is done in a runit script. I wonder if it could be done directly when the
rootfs is mounted.


<br />
@footer@
