{ lib, pkgs, config, ... }:

with lib;

{
  options = {
    boot = {
      devSize = mkOption {
        default = "5%";
        example = "32m";
        type = types.str;
      };
      devShmSize = mkOption {
        default = "50%";
        example = "256m";
        type = types.str;
      };
      runSize = mkOption {
        default = "25%";
        example = "256m";
        type = types.str;
       };
    };
  };
  config = {
    system.build.bootStage2 = pkgs.runCommand "stage-2" {
      text = ./stage-2-init.sh;
      passAsFile = [ "text" ];
      preferLocalBuild = true;
      allowSubstitutes = false;
    } ''
      cp ${./stage-2-init.sh} "$out"
      substituteInPlace $out --subst-var shell
      substituteInPlace $out --subst-var-by stage-2 $out
      substituteInPlace $out --subst-var-by path ${config.system.path}
      substituteInPlace $out --subst-var-by toplevel ${config.system.build.toplevel}
      chmod +x "$out"
    '';
  };
}
