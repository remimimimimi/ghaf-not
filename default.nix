{ configuration ? import ./configuration.nix
, nixpkgs ? <nixpkgs>
, extraModules ? []
, system ? builtins.currentSystem
}:

let
  pkgs = import nixpkgs { inherit system; config = {}; };
  pkgsModule = rec {
    _file = ./default.nix;
    key = _file;
    config = {
      nixpkgs.localSystem = { inherit system; };
    };
  };
  baseModules = [
      ./base.nix
      ./system-path.nix
      ./stage-1.nix
      ./stage-2.nix
      ./runit.nix
      <nixpkgs/nixos/modules/system/etc/etc.nix>
      <nixpkgs/nixos/modules/system/activation/activation-script.nix>
      <nixpkgs/nixos/modules/misc/nixpkgs.nix>
      <nixpkgs/nixos/modules/system/boot/kernel.nix>
      <nixpkgs/nixos/modules/misc/assertions.nix>
      <nixpkgs/nixos/modules/misc/lib.nix>
      <nixpkgs/nixos/modules/config/sysctl.nix>
      ./nixos-compat.nix
      pkgsModule
  ];
  evalConfig = modules: pkgs.lib.evalModules {
    prefix = [];
    check = true;
    modules = modules ++ baseModules ++ extraModules;
    args = {};
  };
in
rec {
  os = evalConfig [ configuration ];
  config = os.config;

  # Build with nix-build -A <attr>
  stage-1 = os.config.system.build.bootStage1;
  stage-2 = os.config.system.build.bootStage2;
  runvm = os.config.system.build.runvm;
  kernel = os.config.system.build.kernel;
  initrd = os.config.system.build.initialRamdisk;
  rootfs = os.config.system.build.squashfs;
  ext4 = os.config.system.build.ext4;
  raw = os.config.system.build.raw;
  qcow2 = os.config.system.build.qcow2;
  toplevel = os.config.system.build.toplevel;
  path = os.config.system.path;
  dist = os.config.system.build.dist;
  extra-utils = os.config.system.build.extraUtils;
  shrunk = os.config.system.build.shrunk;

  # Evaluate with nix-instantiate --eval --strict -A <attr>
  root-modules = os.config.system.build.rootModules;
  cmdline = os.config.boot.kernelParams;
}
