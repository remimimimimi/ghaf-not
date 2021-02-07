#! ${pkgs.stdenv.shell}

# To use this script, the `live` and `simpleStaticIp` options must be set to
# true.

exec ${pkgs.qemu_kvm}/bin/qemu-kvm \
  -name not-os \
  -m 512 \
  -kernel ${config.system.build.kernel}/bzImage \
  -initrd ${config.system.build.initialRamdisk}/initrd \
  -drive index=0,id=drive1,file=${config.system.build.squashfs},readonly,media=cdrom,format=raw,if=virtio \
  -append "console=ttyS0 ${toString config.boot.kernelParams} quiet panic=-1" \
  -device virtio-net,netdev=net0 \
  -netdev user,id=net0,net=10.0.2.0/24,host=10.0.2.2,dns=10.0.2.3,hostfwd=tcp::2222-:22 \
  -device virtio-rng-pci \
  -nographic \
  -no-reboot

# TODO Doesn't seem supported anymore, must be added back in some way.
#  -redir tcp:8000::80 \
