#! /usr/bin/env bash

# Script to create a qcow2 image.
#
# This doesn't use the same mechanism than nix-exp/exp03 because it relies on
# too much NixOS-specific things.
# Currently, this means than Nix is not installed in the vm.

# Warning: the losetup | grep doesn't work if the same filename is listed more
# than once.

# Mmm. It seems sudo losetup results in having loop0p1 but without sudo, nope.

# # Require grub2 package in PATH. Mmm couldn't get the grub-install right.
# Or rathe syslinux.

dd if=/dev/zero of=image.raw bs=1M seek=511 count=1
dd if=/dev/zero of=image.raw bs=512 count=2049 conv=notrunc

echo "2048,,83,*" | sfdisk ./image.raw

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
#sudo mkdir -p rootfs-mnt/{boot/grub,boot/grub2,etc}
sudo mkdir -p rootfs-mnt/{boot/extlinux,etc,nix,var}

nix-build --option substitute false --attr dist
sudo cp result/kernel rootfs-mnt/boot/vmlinuz
sudo cp result/initrd rootfs-mnt/boot/
sudo unsquashfs -d rootfs-mnt/nix/store result/root.squashfs
sudo cp -a _site rootfs-mnt/var/www
echo "LABEL=rootfs / auto defaults 1 1" > a
sudo cp a rootfs-mnt/etc/fstab
echo "(hd0) /dev/loop0" > a
#sudo cp a rootfs-mnt/boot/grub/device.map
#sudo cp a rootfs-mnt/boot/grub2/device.map
#cat > a <<EOF
#menuentry 'not-os' {
#   linux (hd0,msdos1)/boot/vmlinuz
#  initrd (hd0,msfos1)/boot/initrd
#}
#EOF
#sudo cp a rootfs-mnt/boot/grub/grub.cfg
#sudo cp a rootfs-mnt/boot/grub2/grub.cfg

#grub-install --boot-directory=rootfs-mnt/boot/ "$DEV" --target=i386-pc

cat > a <<EOF
DEFAULT Live
LABEL Live
  KERNEL /boot/vmlinuz
  APPEND initrd=/boot/initrd console=ttyS0 root=/dev/vda1
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
