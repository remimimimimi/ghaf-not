---
title: not-os
---

## initrd

```
$ nix-build -A initrd
@result@
```

An initrd is a temporary root file system living in memory. It is part of the
startup process and provides an early user-space to prepare the system before
the real root file system can be mounted.

In particular in our case, it packages busybox. Given we are using a gzipped
cpio archive with an init script, Wikipedia suggests we are actually using the
initramfs scheme instead of the initrd scheme.

To explore the result, we can extract the content of the initrd in a temporary
directory as follow:

```
$ mkdir tmp ; cd tmp
$ zcat ../result/initrd | cpio -idmv
$ find -maxdepth 3
.
./init
./sys
./proc
./dev
./nix
./nix/store
./nix/store/mpqsj1j686hd669qsdma2pr2b65b144q-stage-1
./nix/store/70jf5sm6750jbbsirv6rqihwj22gsbvj-linux-4.14.84-shrunk
./nix/store/flvbcnaszzif58xvdnbbsk8fxfz473k6-dhcpHook
./nix/store/w5dbz7ig5s3g0c1xz7aqqs9klghhq4lm-extra-utils
```

- `init` is a symlink pointing to stage-1.
- The `dev/`, `proc/`, and `sys/` directories are empty.
- extra-utils (i.e. busybox, roughly) are packaged there together with a
  collection of Linux kernel modules.
- There is also a `dhcpHook` script (which is emtpty).

The nixpkgs code to create the initrd is at
`pkgs/build-support/kernel/make-initrd.nix` and
`pkgs/build-support/kernel/make-initrd.sh`.

The nixpkgs code to create the collection of modules is at
`pkgs/build-support/kernel/modules-closure.nix` and
`pkgs/build-support/kernel/modules-closure.sh`.




<br />
@footer@
