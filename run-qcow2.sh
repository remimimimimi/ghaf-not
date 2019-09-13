#! /usr/bin/env bash

IMAGE=$(nix-build --option substitute false --attr qcow2 --no-out-link)

qemu-kvm \
  -m 512 \
  -drive index=0,id=drive1,file=$IMAGE,format=qcow2,if=virtio \
  -device virtio-net,netdev=net0 \
  -netdev user,id=net0,net=10.0.2.0/24,host=10.0.2.2,dns=10.0.2.3,hostfwd=tcp::2222-:22 \
  -redir tcp:8000::80 \
  -redir tcp:4430::443 \
  -device virtio-rng-pci \
  -nographic \
  -no-reboot \
  -snapshot
