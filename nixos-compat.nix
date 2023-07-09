{
  config,
  lib,
  ...
}:
with lib; {
  options = {
    systemd = {
      globalEnvironment = mkOption {};
      packages = mkOption {};
      services = mkOption {
        type = types.attrsOf types.unspecified;
      };
      sockets = mkOption {};
      targets = mkOption {};
      tmpfiles = mkOption {};
      user = mkOption {};
    };

    # Copied from nixpkgs nixos/modules/system/boot/stage-1.nix
    boot.initrd.enable = mkOption {
      type = types.bool;
      default = !config.boot.isContainer;
      defaultText = "!config.boot.isContainer";
      description = ''
        Whether to enable the NixOS initial RAM disk (initrd). This may be
        needed to perform some initialisation tasks (like mounting
        network/encrypted file systems) before continuing the boot process.
      '';
    };
  };

  config = {
  };
}
