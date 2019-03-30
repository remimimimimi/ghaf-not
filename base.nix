{ pkgs, config, lib, ... }:

with lib;
with import ./templating.nix { inherit pkgs; };

let
  # ext4 = pkgs.callPackage <nixpkgs/nixos/lib/make-ext4-fs.nix> ({
  ext4 = pkgs.callPackage ./make-ext4-fs.nix ({
    storePaths = [ config.system.build.toplevel config.system.build.bootStage2 ];
    volumeLabel = "rootfs";
    kernel = config.system.build.kernel;
    initialRamdisk = config.system.build.initialRamdisk;
  });
in
{
  options = {
    system.build = mkOption {
      internal = true;
      default = {};
      description = "Attribute set of derivations used to setup the system.";
    };
    boot.isContainer = mkOption {
      type = types.bool;
      default = false;
    };
    hardware.firmware = mkOption {
      type = types.listOf types.package;
      default = [];
      apply = list: pkgs.buildEnv {
        name = "firmware";
        paths = list;
        pathsToLink = [ "/lib/firmware" ];
        ignoreCollisions = true;
      };
    };
    not-os.live = mkOption {
      type = types.bool;
      description = "enable nix-daemon and a writeable store";
    };
    not-os.simpleStaticIp = mkOption {
      type = types.bool;
      default = false;
      description = "set a static ip of 10.0.2.15";
    };
  };
  config = {
    environment.systemPackages = lib.optional config.not-os.live pkgs.nix;
    nixpkgs.config = {
      packageOverrides = self: {
        utillinux = self.utillinux.override { systemd = null; };
        dhcpcd = self.dhcpcd.override { udev = null; };
      };
    };
    environment.etc = {
      "nix/nix.conf".source = pkgs.runCommand "nix.conf" {} ''
        extraPaths=$(for i in $(cat ${pkgs.writeReferencesToFile pkgs.stdenv.shell}); do if test -d $i; then echo $i; fi; done)
        cat > $out << EOF
        build-use-sandbox = true
        build-users-group = nixbld
        build-sandbox-paths = /bin/sh=${pkgs.stdenv.shell} $(echo $extraPaths)
        build-max-jobs = 1
        build-cores = 4
        EOF
      '';
      bashrc.text = "export PATH=/run/current-system/sw/bin";
      profile.text = "export PATH=/run/current-system/sw/bin";
      "resolv.conf".text = "nameserver 10.0.2.3";
      passwd.text = ''
        root:x:0:0:System administrator:/root:/run/current-system/sw/bin/bash
        sshd:x:498:65534:SSH privilege separation user:/var/empty:/run/current-system/sw/bin/nologin
        nixbld1:x:30001:30000:Nix build user 1:/var/empty:/run/current-system/sw/bin/nologin
        nixbld2:x:30002:30000:Nix build user 2:/var/empty:/run/current-system/sw/bin/nologin
        nixbld3:x:30003:30000:Nix build user 3:/var/empty:/run/current-system/sw/bin/nologin
        nixbld4:x:30004:30000:Nix build user 4:/var/empty:/run/current-system/sw/bin/nologin
        nixbld5:x:30005:30000:Nix build user 5:/var/empty:/run/current-system/sw/bin/nologin
        nixbld6:x:30006:30000:Nix build user 6:/var/empty:/run/current-system/sw/bin/nologin
        nixbld7:x:30007:30000:Nix build user 7:/var/empty:/run/current-system/sw/bin/nologin
        nixbld8:x:30008:30000:Nix build user 8:/var/empty:/run/current-system/sw/bin/nologin
        nixbld9:x:30009:30000:Nix build user 9:/var/empty:/run/current-system/sw/bin/nologin
        nixbld10:x:30010:30000:Nix build user 10:/var/empty:/run/current-system/sw/bin/nologin
        nobody:x:65534:65534:Unprivileged account:/var/empty:/run/current-system/sw/bin/nologin
      '';
      "nsswitch.conf".text = ''
        hosts:     files  dns   myhostname mymachines
        networks:  files dns
      '';
      "services".source = pkgs.iana_etc + "/etc/services";
      group.text = ''
        root:x:0:
        nixbld:x:30000:nixbld1,nixbld10,nixbld2,nixbld3,nixbld4,nixbld5,nixbld6,nixbld7,nixbld8,nixbld9
        nogroup:x:65534
      '';
      "ssh/ssh_host_rsa_key.pub".source = ./ssh/ssh_host_rsa_key.pub;
      "ssh/ssh_host_rsa_key" = { mode = "0600"; source = ./ssh/ssh_host_rsa_key; };
      "ssh/ssh_host_ed25519_key.pub".source = ./ssh/ssh_host_ed25519_key.pub;
      "ssh/ssh_host_ed25519_key" = { mode = "0600"; source = ./ssh/ssh_host_ed25519_key; };
    };
    boot.kernelParams = [ ];
    boot.kernelPackages = pkgs.linuxPackages;
    system.build.earlyMountScript = pkgs.writeScript "dummy" ''
    '';

    system.build.runvm =
      writeInterpolatedFile "runvm" { inherit pkgs config; } ./strings/runvm.sh;

    system.build.dist = pkgs.runCommand "dist" {} ''
      mkdir $out
      cp ${config.system.build.kernel}/*Image $out/kernel
      cp ${config.system.build.initialRamdisk}/initrd $out/initrd
      cp ${config.system.build.squashfs} $out/root.squashfs
      echo "${builtins.unsafeDiscardStringContext (toString config.boot.kernelParams)}" \
        > $out/command-line
    '';

    system.activationScripts.users = ''
      # dummy to make setup-etc happy
    '';
    system.activationScripts.groups = ''
      # dummy to make setup-etc happy
    '';

    # nix-build -A system.build.toplevel && du -h $(nix-store -qR result) --max=0 -BM|sort -n
    system.build.toplevel = pkgs.runCommand "toplevel" {
      activationScript = config.system.activationScripts.script;
    } ''
      mkdir $out
      ln -s ${config.system.path} $out/sw
      echo "$activationScript" > $out/activate
      substituteInPlace $out/activate --subst-var out
      chmod u+x $out/activate
      unset activationScript
    '';
    # nix-build -A squashfs && ls -lLh result
    system.build.squashfs = pkgs.callPackage <nixpkgs/nixos/lib/make-squashfs.nix> {
      storeContents = [ config.system.build.toplevel config.system.build.bootStage2 ];
    };
    system.build.ext4 = ext4;
    system.build.raw = pkgs.callPackage ({ stdenv, dosfstools, e2fsprogs, mtools, libfaketime, utillinux, syslinux }: stdenv.mkDerivation {
      name = "raw";

      nativeBuildInputs = [ dosfstools e2fsprogs mtools libfaketime utillinux syslinux ];

      buildCommand = ''
        export img=$out

        # Create the image file sized to fit the rootfs, plus 20M of slack
        rootSizeBlocks=$(du -B 512 --apparent-size ${ext4} | awk '{ print $1 }')
        bootSizeBlocks=$((20 * 1024 * 1024 / 512))
        imageSize=$((rootSizeBlocks * 512 + bootSizeBlocks * 512 + 20 * 1024 * 1024))
        #truncate -s $imageSize $img
        dd if=/dev/zero of=$img bs=1M seek=511 count=1
        dd conv=notrunc if=/dev/zero of=$img bs=512 count=2049

        # type=83 is 'Linux'.
        sfdisk $img <<EOF
            label: dos
            label-id: 0x20000000

            start=8M, size=$bootSizeBlocks, type=b, bootable
            start=28M, type=83
        EOF

        # Copy the rootfs into image
        eval $(partx $img -o START,SECTORS --nr 2 --pairs)
        dd conv=notrunc if=${ext4} of=$img seek=$START count=$SECTORS

        # Create a FAT32 /boot partition of suitable size into boot.raw
        eval $(partx $img -o START,SECTORS --nr 1 --pairs)
        truncate -s $((SECTORS * 512)) boot.raw
        faketime "1970-01-01 00:00:00" mkfs.vfat -F 16 -i 0x20000000 -n BOOT boot.raw

        # Populate the files intended for /boot
        mkdir -p syslinux boot/syslinux
        cat > boot/syslinux/syslinux.cfg <<EOF
        PROMPT 1
        TIMEOUT 50
        DEFAULT play
        LABEL play
          LINUX ../vmlinuz
          APPEND console=ttyS0 root=/dev/vda1
          INITRD ../initrd
        EOF
        cp ${config.system.build.kernel}/bzImage boot/vmlinuz
        cp ${config.system.build.initialRamdisk}/initrd boot/initrd
        cp boot/syslinux/syslinux.cfg syslinux/
        cp ${syslinux}/share/syslinux/*.c32 boot/syslinux/

        # Copy the populated /boot into the SD image
        (cd boot; mcopy -bpsvm -i ../boot.raw ./* ::)
        (cd syslinux; mcopy -bpsvm -i ../boot.raw ./* ::)
        syslinux --directory /boot/syslinux --install boot.raw
        dd conv=notrunc if=boot.raw of=$img seek=$START count=$SECTORS
        dd if=${syslinux}/share/syslinux/mbr.bin of=$img bs=440 count=1 conv=notrunc
      '';
    }) {};
    system.build.qcow2 = pkgs.runCommand "qcow2" {
    } ''
      ${pkgs.qemu}/bin/qemu-img convert -f raw -O qcow2 ${config.system.build.raw} $out
    '';
  };
}
