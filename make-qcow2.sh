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

dd if=/dev/zero of=image.raw bs=1M seek=511 count=1
dd if=/dev/zero of=image.raw bs=512 count=2049 conv=notrunc

sfdisk ./image.raw <<EOF
    label: dos
    label-id: 0x20000000

    start=2048, type=83, bootable
EOF

sudo losetup --show -f -P image.raw

export DEV=`losetup | grep image.raw | awk '{print $1}'`
export DEV1="${DEV}p1"
echo "Device is ${DEV}."

if [ "${DEV}" != "/dev/loop0" ] ; then
  echo "Resulting device is not what I expected."
  losetup -d ${DEV}
  exit 1
fi

# extlinux below requires a 32bit ext4. 64bit didn't seem to be a problem when
# not unsquashing the rootfs but it caused a kernel panic otherwise.
sudo mkfs.ext4 -q -F -O ^64bit -L rootfs "${DEV1}"

mkdir -p rootfs-mnt
sudo mount "${DEV1}" rootfs-mnt
sudo mkdir -p rootfs-mnt/{boot/extlinux,etc,nix,var}

nix-build --option substitute false --attr dist
sudo cp result/kernel rootfs-mnt/boot/vmlinuz
sudo cp result/initrd rootfs-mnt/boot/
sudo unsquashfs -d rootfs-mnt/nix/store result/root.squashfs
sudo cp -a _site rootfs-mnt/var/www
echo "LABEL=rootfs / auto defaults 1 1" > a
sudo cp a rootfs-mnt/etc/fstab

cat > a <<EOF
DEFAULT Live
LABEL Live
  KERNEL /boot/vmlinuz
  APPEND initrd=/boot/initrd root=/dev/vda1
TIMEOUT 10
PROMPT 0
EOF
sudo cp a rootfs-mnt/boot/extlinux/extlinux.conf
rm a

sudo extlinux -i rootfs-mnt/boot/extlinux
dd if=/nix/store/s4rbsvzj5nrq8bq5ni4d5rpl91h6c859-syslinux-2015-11-09/share/syslinux/mbr.bin of="${DEV}" bs=440 count=1

sudo umount rootfs-mnt
losetup -d ${DEV}

qemu-img convert -f raw -O qcow2 image.raw image.qcow2
