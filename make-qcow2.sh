#! /usr/bin/env bash

# Script to create a qcow2 image.
#
# The main difference with the raw and qcow2 attributes in default.nix, is that
# here we only use a single ext4 partition (which thus contain the /boot
# files).
#
# This is necessary for instance to use the Digital Ocean custom image feature
# (which only supports EXT3 and EXT4).
#
# This doesn't use the same mechanism than nix-exp/exp03 because it relies on
# too much NixOS-specific things.  Currently, this means than Nix is not
# installed in the vm.

# Warning: the losetup | grep doesn't work if the same filename is listed more
# than once.

# Mmm. It seems sudo losetup results in having loop0p1 but without sudo, nope.

# This require the syslinux package, e.g. with nix-shell -p.

EMBED_SITE="${EMBED_SITE:-_site}"

nix-build --attr images
cp result/image.raw .

sudo losetup --show -f -P image.raw

export DEV=`losetup | grep image.raw | awk '{print $1}'`
export DEV1="${DEV}p1"
echo "Device is ${DEV}."

if [ "${DEV}" != "/dev/loop0" ] ; then
  echo "Resulting device is not what I expected."
  losetup -d ${DEV}
  exit 1
fi

mkdir -p rootfs-mnt
sudo mount "${DEV1}" rootfs-mnt
sudo rsync -a "${EMBED_SITE}/" rootfs-mnt/var/www/noteed.com/

sudo umount rootfs-mnt
losetup -d ${DEV}

qemu-img convert -f raw -O qcow2 image.raw image.qcow2
