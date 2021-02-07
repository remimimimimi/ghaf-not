{ lib, ... }:

with lib;

{
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
  };
  config = {
  };
}
