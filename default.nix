{
  configuration ? import ./configuration.nix,
  pkgs,
  #, pkgs ? import <nixpkgs> { inherit system; config = {}; }
  extraModules ? [],
  system ? builtins.currentSystem,
}: let
  pkgsModule = rec {
    _file = ./default.nix;
    key = _file;
    config = {
      nixpkgs.localSystem = {inherit system;};
    };
  };

  nixosModulesPath = pkgs.path + "/nixos/modules";

  baseModules = [
    ./base.nix
    ./system-path.nix
    ./stage-1.nix
    ./stage-2.nix
    ./runit.nix
    ./etc.nix
    (nixosModulesPath + "/system/activation/activation-script.nix")
    (nixosModulesPath + "/misc/nixpkgs.nix")
    (nixosModulesPath + "/system/boot/kernel.nix")
    (nixosModulesPath + "/misc/assertions.nix")
    (nixosModulesPath + "/misc/lib.nix")
    (nixosModulesPath + "/config/sysctl.nix")
    ./nixos-compat.nix
    pkgsModule
  ];

  evalConfig = modules:
    pkgs.lib.evalModules {
      modules = modules ++ baseModules ++ extraModules;
    };
in rec {
  os = evalConfig [configuration];
  config = os.config;

  # Build with nix-build -A <attr>
  stage-1 = os.config.system.build.bootStage1;
  stage-2 = os.config.system.build.bootStage2;
  runvm = os.config.system.build.runvm;
  kernel = os.config.system.build.kernel;
  initrd = os.config.system.build.initialRamdisk;
  rootfs = os.config.system.build.squashfs;
  images = os.config.system.build.images;
  ext4 = os.config.system.build.ext4;
  boot = os.config.system.build.boot;
  syslinux = os.config.system.build.syslinux;
  raw = os.config.system.build.raw;
  qcow2 = os.config.system.build.qcow2;
  toplevel = os.config.system.build.toplevel;
  path = os.config.system.path;
  dist = os.config.system.build.dist;
  extra-utils = os.config.system.build.extraUtils;
  shrunk = os.config.system.build.shrunk;
}
