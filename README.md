# not-os

This is a branch with some notes for myself (Thu).


## Tests

To ensure the resulting OS can boot under QEMU:

```
$ nix-build -A tests.boot.normalBoot.x86_64-linux release.nix
```

After the build completes, the test is run and looks like:

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

![tests.boot.normalBoot.x86_64-linux](https://github.com/noteed/not-os/raw/notes/images/vm-test-run-normal-boot.png)


## Build

Those two commands are equivalent:

```
$ nix-build
$ nix-build -A runner
```

This will create a `result` symlink to a script. The script is just a call to
qemu-kvm with the right parameters. In particular the sqashfs image, the
kernel, and the initrd.


## Run

In my case, running the above script results in an error:

```
$ ./result
qemu-system-x86_64: -net nic,vlan=0,model=virtio: 'vlan' is deprecated. Please use 'netdev' instead.
qemu-system-x86_64: Invalid parameter 'dump'
```

I simply made a copy (`./runner`) and removed the `-net dump,vlan=0` line.

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
