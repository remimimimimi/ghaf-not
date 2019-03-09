#!@shell@

export PATH=@path@/bin/

echo
echo "[37;40mEntering stage-2...[0m"
echo @stage-2@

mkdir -p /proc /sys /dev /tmp /var/log /etc /root /run /nix/var/nix/gcroots
mount -t proc proc /proc
mount -t sysfs sys /sys
mount -t devtmpfs devtmpfs /dev
mkdir /dev/pts /dev/shm
mount -t devpts devpts /dev/pts
mount -t tmpfs tmpfs /run
mount -t tmpfs tmpfs /dev/shm

@toplevel@/activate

exec runit
