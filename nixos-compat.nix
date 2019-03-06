{ lib, ... }:

with lib;

{
  options = {
    systemd.services = mkOption { };
  };
  config = {
  };
}
