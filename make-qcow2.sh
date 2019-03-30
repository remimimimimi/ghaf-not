#! /usr/bin/env bash

# Script to create a qcow2 image.
#
# This doesn't use the same mechanism than nix-exp/exp03 because it relies on
# too much NixOS-specific things.
# Currently, this means than Nix is not installed in the vm.

# Warning: the losetup | grep doesn't work if the same filename is listed more
# than once.

# Mmm. It seems sudo losetup results in having loop0p1 but without sudo, nope.

# This require the syslinux package, e.g. with nix-shell -p.
# debugfs comes from e2fsprogs.

nix-build --option substitute false --attr qcow2 # TODO should be called raw

cp result ./image.raw
sudo chmod u+w image.raw


sudo losetup --show -f -P image.raw
sudo mount /dev/loop0p1 rootfs-mnt/

sudo extlinux -i rootfs-mnt/boot/extlinux
dd if=/nix/store/s4rbsvzj5nrq8bq5ni4d5rpl91h6c859-syslinux-2015-11-09/share/syslinux/mbr.bin of="/dev/loop0" bs=440 count=1

sudo umount rootfs-mnt
losetup -d "/dev/loop0"

qemu-img convert -f raw -O qcow2 image.raw image.qcow2
