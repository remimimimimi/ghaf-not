{ lib, pkgs, config, ... }:

with lib;
let
  rootModules =
    config.boot.initrd.availableKernelModules ++
    config.boot.initrd.kernelModules;
  modules = pkgs.makeModulesClosure {
    rootModules = rootModules;
    kernel = config.system.build.kernel;
    firmware = config.hardware.firmware;
    allowMissing = true;
  };
  dhcpcd = pkgs.dhcpcd.override { udev = null; };
  extraUtils = pkgs.runCommandCC "extra-utils"
  {
    buildInputs = [ pkgs.nukeReferences ];
    allowedReferences = [ "out" ];
  } ''
    set +o pipefail
    mkdir -p $out/bin $out/lib
    ln -s $out/bin $out/sbin

    copy_bin_and_libs() {
      [ -f "$out/bin/$(basename $1)" ] && rm "$out/bin/$(basename $1)"
      cp -pd $1 $out/bin
    }

    # Copy Busybox
    for BIN in ${pkgs.busybox}/{s,}bin/*; do
      copy_bin_and_libs $BIN
    done

    copy_bin_and_libs ${pkgs.dhcpcd}/bin/dhcpcd

    # Copy ld manually since it isn't detected correctly
    cp -pv ${pkgs.glibc.out}/lib/ld*.so.? $out/lib

    # Copy all of the needed libraries
    find $out/bin $out/lib -type f | while read BIN; do
      echo "Copying libs for executable $BIN"
      LDD="$(ldd $BIN)" || continue
      LIBS="$(echo "$LDD" | awk '{print $3}' | sed '/^$/d')"
      for LIB in $LIBS; do
        TGT="$out/lib/$(basename $LIB)"
        if [ ! -f "$TGT" ]; then
          SRC="$(readlink -e $LIB)"
          cp -pdv "$SRC" "$TGT"
        fi
      done
    done

    # Strip binaries further than normal.
    chmod -R u+w $out
    stripDirs "lib bin" "-s"

    # Run patchelf to make the programs refer to the copied libraries.
    find $out/bin $out/lib -type f | while read i; do
      if ! test -L $i; then
        nuke-refs -e $out $i
      fi
    done

    find $out/bin -type f | while read i; do
      if ! test -L $i; then
        echo "patching $i..."
        patchelf --set-interpreter $out/lib/ld*.so.? --set-rpath $out/lib $i || true
      fi
    done

    # Make sure that the patchelf'ed binaries still work.
    echo "testing patched programs..."
    $out/bin/ash -c 'echo hello world' | grep "hello world"
    export LD_LIBRARY_PATH=$out/lib
    $out/bin/mount --help 2>&1 | grep -q "BusyBox"
  '';
  shell = "${extraUtils}/bin/ash";
  dhcpHook = pkgs.writeScript "dhcpHook" ''
  #!${shell}
  '';
  bootStage1Text = ''
    #!${shell}
    echo "[37;40mEntering stage-1...[0m"
    echo @stage-1@

    export PATH=${extraUtils}/bin/

    echo Creating base file systems...
    mkdir -p /proc /sys /dev /etc/udev /tmp /run/ /lib/ /mnt/ /var/log /bin
    mount -t devtmpfs devtmpfs /dev/
    mount -t proc proc /proc
    mount -t sysfs sysfs /sys

    ln -s ${shell} /bin/sh
    ln -s ${modules}/lib/modules /lib/modules

    root=/dev/vda
    realroot=tmpfs
    for o in $(cat /proc/cmdline); do
      case $o in
        root=*)
          set -- $(IFS==; echo $o)
          root=$2
          ;;
        netroot=*)
          set -- $(IFS==; echo $o)
          mkdir -pv /var/run /var/db
          sleep 5
          dhcpcd eth0 -c ${dhcpHook}
          tftp -g -r "$3" "$2"
          root=/root.squashfs
          ;;
        realroot=*)
          set -- $(IFS==; echo $o)
          realroot=$2
          ;;
      esac
    done

    echo Using ${extraUtils}...
    echo Using ${modules}...

    for x in ${lib.concatStringsSep " " config.boot.initrd.kernelModules}; do
      echo Loading kernel module $x...
      modprobe $x
    done

    #mount -t tmpfs root /mnt/ -o size=1G || exec ${shell}
    #chmod 755 /mnt/
    #mkdir -p /mnt/nix/store/

    ${if config.not-os.live then ''
    echo Creating writable Nix store...
    mkdir -p /mnt/nix/.ro-store /mnt/nix/.overlay-store /mnt/nix/store
    mount $root /mnt/nix/.ro-store -t squashfs
    mount tmpfs -t tmpfs /mnt/nix/.overlay-store -o size=1G
    mkdir -p /mnt/nix/.overlay-store/work /mnt/nix/.overlay-store/rw
    modprobe overlay
    mount -t overlay overlay -o lowerdir=/mnt/nix/.ro-store,upperdir=/mnt/nix/.overlay-store/rw,workdir=/mnt/nix/.overlay-store/work /mnt/nix/store
    '' else ''
    echo Creating readonly Nix store...
    # maybe libcrc32c is not necessary
    modprobe jbd2
    modprobe fscrypto
    modprobe mbcache
    modprobe crc16
    modprobe libcrc32c
    modprobe crc32c_generic
    modprobe ext4
    mount -t ext4 -o rw,exec $root /mnt
    ''}

    echo Switching root filesystem...
    exec env -i $(type -P switch_root) /mnt/ \
      ${builtins.unsafeDiscardStringContext (toString config.system.build.bootStage2)}
    exec ${shell}
  '';
  bootStage1 = pkgs.runCommand "stage-1" {
    text = bootStage1Text;
    passAsFile = [ "text" ];
    preferLocalBuild = true;
    allowSubstitutes = false;
  } ''
    mv "$textPath" "$out"
    substituteInPlace $out --subst-var-by stage-1 $out
    chmod +x "$out"
  '';
  makeInitrd = { contents, compressor ? "gzip -9n", prepend ? [ ], keepStorePath }:
    pkgs.callPackage build-support/kernel/make-initrd.nix {
      inherit contents compressor prepend keepStorePath;
    };
  initialRamdisk = pkgs.makeInitrd {
    contents = [ { object = bootStage1; symlink = "/init"; } ];
  };
in
{
  options = {
  };
  config = {
    system.build.bootStage1 = bootStage1;
    system.build.initialRamdisk = initialRamdisk;
    system.build.extraUtils = extraUtils;
    system.build.shrunk = modules;
    system.build.rootModules = rootModules;
    boot.initrd.availableKernelModules = [ "jbd2" "fscrypto" "mbcache" "crc16" "libcrc32c" "crc32c_generic" "ext4" ];
    boot.initrd.kernelModules =
      [ "tun" "loop" "squashfs" ] ++
      (lib.optional config.not-os.live "overlay");
  };
}
