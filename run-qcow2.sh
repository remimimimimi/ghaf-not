#! /usr/bin/env bash

qemu-kvm \
  -m 512 \
  -drive index=0,id=drive1,file=image.raw,format=raw,if=virtio \
  -device virtio-net,netdev=net0 \
  -netdev user,id=net0,net=10.0.2.0/24,host=10.0.2.2,dns=10.0.2.3,hostfwd=tcp::2222-:22 \
  -redir tcp:8000::80 \
  -device virtio-rng-pci \
  -nographic \
  -no-reboot \
  -snapshot
