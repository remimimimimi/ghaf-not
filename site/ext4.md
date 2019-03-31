---
title: not-os
---

## ext4

```
$ nix-build -A ext4
@result@
```

The ext4 derivation, defined as `config.system.build.ext4`, creates a rootfs
image in the ext4 format. It contains the closures of toplevel and a
registration file.

The rootfs is also available as a [squashfs](rootfs.html) image.

To explore the result, we can extract the content of the rootfs in a temporary
directory as follow:

```
$ mkdir -p tmp/ext4-root ; cd tmp
$ sudo mount $(readlink -fn ../result) ext4-root
$ find -maxdepth 2
.
./ext4-root
./ext4-root/5f18ah2yzyf4mmnn8jqqb7aws91rw55v-ssh_host_rsa_key.pub
./ext4-root/wqfpawgsigwnz2bk1ygkfya7802jxl9c-iputils-20180629
./ext4-root/p54mjqlrngzzyb2892489b4hffgz03g2-aws-sdk-cpp-1.5.17
./ext4-root/jaiq6xgyhhl84826lrsxbgdy5sm9n8wx-nixos.conf
...
```

The derivation is defined as a call to `nixpkgs/nixos/lib/make-ext4-fs.nix`,
passing toplevel as argument. The closure is constructed by
`nixpkgs/build-support/closure-info.nix`. The ext4 file system is populated
using the `debugfs` command-line tool provided by `e2fsprogs`. The beauty of
using debugfs is that no root privilege nor loop device are required.

A call to `nix-store --load-db` with the registration file found in the rootfs
is done in a runit script. I wonder if it could be done directly when the
rootfs is mounted.


<br />
@footer@
