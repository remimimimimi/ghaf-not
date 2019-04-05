{ pkgs
, config
}:

let

  prepareImage = ''
    dd if=/dev/zero of=image.raw bs=1M seek=511 count=1
    dd if=/dev/zero of=image.raw bs=512 count=2049 conv=notrunc

    ${pkgs.utillinux}/bin/sfdisk ./image.raw <<EOF
      label: dos
      label-id: 0x20000000

      start=2048, type=83, bootable
    EOF

    # Providing a diskImage variable means the VM will get a disk as /dev/vda.
    diskImage=image.raw
  '';

  copyImage = ''
    ${pkgs.qemu}/bin/qemu-img convert -f raw -O qcow2 -c $diskImage $out/image.qcow2
    cp $diskImage $out/
  '';

  buildImage = ''
    # extlinux below requires a 32bit ext4. 64bit didn't seem to be a problem
    # when not unsquashing the rootfs but it caused a kernel panic otherwise.
    ${pkgs.e2fsprogs}/bin/mkfs.ext4 -q -F -O ^64bit -L rootfs /dev/vda1

    mkdir /mnt
    ${pkgs.utillinux}/bin/mount /dev/vda1 /mnt
    mkdir -p /mnt/{boot/extlinux,etc,nix,var/www}

    cp ${config.system.build.kernel}/bzImage /mnt/boot/vmlinuz
    cp ${config.system.build.initialRamdisk}/initrd /mnt/boot/
    # TODO Don't do it via the squashfs.
    ${pkgs.squashfsTools}/bin/unsquashfs -d /mnt/nix/store ${config.system.build.squashfs}
    # cp ${config.system.build.ext4} image.ext4


    # TODO
    # cp -a "DOLLAR{EMBED_SITE}" /mnt/var/www/noteed.com
    mkdir -p /mnt/var/www/{acme/.well-known/acme-challenge,noteed.com}
    echo Hello. > /mnt/var/www/noteed.com/index.html
    echo "LABEL=rootfs / auto defaults 1 1" > /mnt/etc/fstab

    cat > /mnt/boot/extlinux/extlinux.conf <<EOF
    DEFAULT Live
    LABEL Live
      KERNEL /boot/vmlinuz
      APPEND initrd=/boot/initrd root=/dev/vda1 console=ttyS0
    TIMEOUT 10
    PROMPT 0
    EOF

    ${pkgs.syslinux}/bin/extlinux -i /mnt/boot/extlinux
    dd if=${pkgs.syslinux}/share/syslinux/mbr.bin of=/dev/vda bs=440 count=1

    ${pkgs.utillinux}/bin/umount /mnt
  '';

in pkgs.vmTools.runInLinuxVM (
  pkgs.runCommand "build-image"
    { preVM = prepareImage; postVM = copyImage; }
    buildImage
)
