# not-os

This is a branch of the not-os repository with some notes for myself (Thu).

I also removed some things (e.g. RPi and ipxe support) to make it easier to
explore.

not-os is a minimal OS based on the Linux kernel, coreutils, and runit. It is
also the build script to build such an OS.

As a build tool, not-os uses nixpkgs and in particular the [NixOS module
system](https://nixos.wiki/wiki/NixOS_Modules) to build the three main
components of a Linux-based operating system:

- a kernel (`config.system.build.kernel`)
- an initrd (`config.system.build.initialRamdisk`)
- a rootfs (`config.system.build.squashfs`)

Given the three above derivations, it is then trivial to leverage Nix to
generate the appropriate qemu-kvm invocation as a script, runner.

The `tests/` directory shows also how to run a VM using the Nix testing
infrastructure.

In addition to the three above derivations, a few intermediate results are
defined in `default.nix` to make it easy to explore this project. They are also
described in this document.


## Build

```
$ nix-build -A runner
```

This will create a `result` symlink to a script. The script is just a call to
qemu-kvm with the right parameters. In particular the kernel, the initrd, and
the squashfs image.


## Run

```
$ ./runner
[...]
<<< NotOS Stage 2 >>>

setting up /etc...
- runit: $Id: 25da3b86f7bed4038b8a039d2f8e8c9bbcf0822b $: booting.
- runit: enter stage: /etc/runit/1
 3 Nov 10:59:00 ntpdate[106]: no servers can be used, exiting
- runit: leave stage: /etc/runit/1
- runit: enter stage: /etc/runit/2
1.97 0.01
```

You can type `ctrl-a x` to quit. You can also enter the QEMU monitor with
`ctrl-a c`, then e.g. type `screendump filename.ppm` to capture an image like
the one in the test, then `quit` to terminate QEMU.


## Linux build slave

(Removed in this branch.)

In addition of the default expression, there is also a build target to run a
not-os VM as a Nix build machine. Its script doesn't have the `-net
dump,vlan=0` line and adds a disk but otherwise is the same.

It can be built with (adapt to provide your own SSH public key):

```
$ nix-build linux-build-slave.nix --arg sshKeyFile ~/.ssh/id_rsa.pub
```

Once running (see the [Run](#run) section above), you can SSH into the VM:

```
$ ssh -p 2222 root@127.0.0.1
-bash-4.4#
```


## Tests

To ensure the resulting OS can boot under QEMU, a test Nix expression is
provided. The test can be run as follow:

```
$ nix-build -A tests.boot.normalBoot.test release.nix
```

After the build completes, the test per-se is run and looks like:

```
running the VM test script
machine: starting vm
machine: QEMU running (pid 8945)
machine: must succeed: sleep 1
machine: waiting for the VM to finish booting
machine# qemu-system-x86_64: warning: vlan 0 is not connected to host network
machine# cSeaBIOS (version rel-1.11.1-0-g0551a4be2c-prebuilt.qemu-project.org)
machine#
machine#
machine# iPXE (http://ipxe.org) 00:03.0 C980 PCI2.10 PnP PMM+17F913A0+17EF13A0 C980

machine#
machine#
machine# Booting from ROM...
machine# Probing EDD (edd=off to disable)... ok
machine# c
machine# <<< NotOS Stage 1 >>>
machine#
machine# '/bin/sh' -> '/nix/store/kvvb9rykrvp1il9s84x648j2jhhsqyj1-extra-utils/bin/ash'
machine# major minor  #blocks  name
machine#
machine#    1        0       4096 ram0
machine#    1        1       4096 ram1
machine#    1        2       4096 ram2
machine#    1        3       4096 ram3
machine#    1        4       4096 ram4
machine#    1        5       4096 ram5
machine#    1        6       4096 ram6
machine#    1        7       4096 ram7
machine#    1        8       4096 ram8
machine#    1        9       4096 ram9
machine#    1       10       4096 ram10
machine#    1       11       4096 ram11
machine#    1       12       4096 ram12
machine#    1       13       4096 ram13
machine#    1       14       4096 ram14
machine#    1       15       4096 ram15
machine#  254        0      53584 vda
machine# /init: line 66: lsblk: not found
machine# 00:00.0 Class 0600: 8086:1237
machine# 00:01.3 Class 0680: 8086:7113
machine# 00:03.0 Class 0200: 1af4:1000
machine# 00:01.1 Class 0101: 8086:7010
machine# 00:06.0 Class 00ff: 1af4:1005
machine# 00:02.0 Class 0300: 1234:1111
machine# 00:05.0 Class 00ff: 1af4:1005
machine# 00:01.0 Class 0601: 8086:7000
machine# 00:04.0 Class 0780: 1af4:1003
machine# 00:07.0 Class 0100: 1af4:1001
machine# overlay 81920 0 - Live 0xffffffffc0326000
machine# squashfs 57344 0 - Live 0xffffffffc0312000
machine# loop 32768 0 - Live 0xffffffffc02f2000
machine# tun 36864 0 - Live 0xffffffffc02fe000
machine# dm_mod 131072 0 - Live 0xffffffffc02d1000
machine# dax 20480 1 dm_mod, Live 0xffffffffc02b1000
machine# virtio_console 32768 0 - Live 0xffffffffc02c8000
machine# virtio_blk 20480 0 - Live 0xffffffffc02c2000
machine# virtio_rng 16384 0 - Live 0xffffffffc0297000
machine# rng_core 16384 1 virtio_rng, Live 0xffffffffc02b9000
machine# virtio_net 45056 0 - Live 0xffffffffc02a5000
machine# virtio_pci 28672 0 - Live 0xffffffffc028f000
machine# virtio_ring 24576 5 virtio_console,virtio_blk,virtio_rng,virtio_net,virtio_pci, Live 0xffffffffc029e000
machine# virtio 16384 5 virtio_console,virtio_blk,virtio_rng,virtio_net,virtio_pci, Live 0xffffffffc028a000
machine# created directory: '/mnt/nix/.overlay-store/work'
machine# created directory: '/mnt/nix/.overlay-store/rw'
machine#
machine# <<< NotOS Stage 2 >>>
machine#
machine# setting up /etc...
machine# - runit: $Id: 25da3b86f7bed4038b8a039d2f8e8c9bbcf0822b $: booting.
machine# - runit: enter stage: /etc/runit/1
machine#  3 Nov 10:16:25 ntpdate[108]: no servers can be used, exiting
machine# - runit: leave stage: /etc/runit/1
machine# - runit: enter stage: /etc/runit/2
machine# 2.02 0.00
machine# connecting to host...
machine: connected to guest root shell
machine# sh: cannot set terminal process group (119): Inappropriate ioctl for device
machine# sh: no job control in this shell
machine: exit status 0
machine: making screenshot ‘test.png’
machine: sending monitor command: screendump /nix/store/4f44yvcd0pyxr4yjc5z0qndrdsm64d0d-vm-test-run-normal-boot/test.png.ppm
machine: waiting for the VM to power off
machine# - runit: leave stage: /etc/runit/2
machine# - runit: enter stage: /etc/runit/3
machine# and down we go
machine# - runit: leave stage: /etc/runit/3
machine# - runit: sending KILL signal to all processes...
machine# - runit: power off...
machine# [    5.479521] reboot: Power down
collecting coverage data
syncing
test script finished in 6.36s
cleaning up
/nix/store/4f44yvcd0pyxr4yjc5z0qndrdsm64d0d-vm-test-run-normal-boot
```

The captured screen looks like:

![tests.boot.normalBoot.test](https://github.com/noteed/not-os/raw/notes/images/vm-test-run-normal-boot.png)


## stage-1

```
$ nix-build -A stage-1
```

stage-1 is a script defined as `config.system.build.bootStage1`. It is the
content of the initrd.

TODO Describe stage-1.

The final action of stage-1 is to call `switch_root` to execute stage-2.

TODO I should extract stage-1-init.sh to be similar to vpsadminos.


## stage-2

```
$ nix-build -A stage-2
```

stage-2 is a script defined as `config.system.build.bootStage2`. It is the
`init` script found in the rootfs, which is built as a squashfs image from
toplevel. See below.


## kernel


## initrd


## rootfs


## toplevel

```
$ nix-build -A toplevel
```

The toplevel contains two scripts and a directory (actually a symlink):

```
$ ls /nix/store/q40j6y70nwhgazvhzrlzh79cjlfik7jv-not-os/
activate  init  sw
```

- `activate` content is the value of `config.system.activationScripts.script`.
  In particular it calls the `setup-etc.pl` script.
- `init` content is the value of `stage-2`, which is
  `stage-2-init.sh`, with `systemConfig` replaced by toplevel's path, and
  `sw/bin/` set as its `$PATH`.
  The `init` script mounts a few special filesystems, calls the `activate`
  script, then execute `runit.
- `sw` is a symlink to `path`, which contains only a `bin/` directory with
  symlinks to base executables (e.g. `[`, `nix-build`, `yes`, ...).

The toplevel is packaged as a squashfs image.

The toplevel's path is sometimes called `systemConfig` or `sysconfig`.


## path


## Experiments

I tried to add `$machine->getTTYText(0);` after the screenshot to
`tests/boot.nix` but it didn't work (missing awk).

I added a service to `runit.nix` that sleep 10 seconds then call poweroff. This
seems to work:

```
$ nix-build linux-build-slave.nix --arg sshKeyFile ~/.ssh/id_rsa.pub 
/nix/store/xkswkf4hxp201a2pbh7pxl485pkixrvg-runner
$ ./result | col -bx > a
qemu-system-x86_64: -net nic,vlan=0,model=virtio: 'vlan' is deprecated. Please use 'netdev' instead.
$ vim a
```

## Implementation notes

- not-os is an awesome example of the Nix ecosystem,
- and in particular how easy it is to define a new rootfs.
- It also shows the [`/etc`
  managememt](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/etc/etc.nix)
  that NixOS provides,
- and put it to good use to define a runit configuration (see the `runit.nix`
  file).


## Related

- [vpsAdminOS](https://vpsadminos.org/) is another Nix distribution based on
  not-os. (It is meaningful to diff this repository against vpsAdminOS `os/`
  directory.)


<hr />

Original README content follows.

not-os is a small experimental OS I wrote for embeded situations, it is based
heavily on NixOS, but compiles down to a kernel, initrd, and a 48mb squashfs

there are also example iPXE config files, that will check the cryptographic
signature over all images, to ensure only authorized files can run on the given
hardware

and I have
[Hydra](http://hydra.earthtools.ca/jobset/not-os/notos#tabs-jobs)
setup and doing automatic builds of not-os against nixos-unstable, including
testing that it can boot under qemu
