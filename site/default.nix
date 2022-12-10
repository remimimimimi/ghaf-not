# This is a set of derivations to create markdown files to document not-os.
# The derivations here use actual parts of the not-os derivations.
#
# Example build instruction:
#  nix-build site/ -A md.runvm

{ configuration ? import ../configuration.nix
, pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/dea79b56f7218ba75653260232c07d2f5ad2f109.tar.gz") { inherit system; config = {}; }
, extraModules ? []
, system ? builtins.currentSystem
}:

let
  artefacts = import ../default.nix
    { inherit configuration extraModules system; };
in rec
{
  cmdline = artefacts.cmdline;
  source.default = ../default.nix;
  strings.runvm = builtins.readFile ../strings/runvm.sh;

  hypertext.footer = builtins.readFile (pkgs.runCommand "footer" {} ''
    sed -n -e '/^<hr/,//p' ${./index.md} > $out
  '');
  hypertext.runvm = builtins.readFile (pkgs.runCommand "runvm.sh" {} ''
sed \
-e \
's@.{config.system.build.kernel}/bzImage@<a href=kernel.html>\0 \&#x24B6</a>@' \
-e \
's@.{config.system.build.initialRamdisk}/initrd@<a href=initrd.html>\0 \&#x24B7</a>@' \
-e \
's@\(.{config.system.build.squashfs}\),@<a href=rootfs.html>\1 \&#x24B8,\n    </a>@' \
-e \
's@\(.{toString config.boot.kernelParams}\)@<a href=cmdline.html>\1 \&#x24B9\n   </a>@' \
-e \
's@10.0.2.2,@\0\n    </a>@' \
${../strings/runvm.sh} > $out
echo >> $out
echo -n $out >> $out
  '');

  md.index = pkgs.writeText "index" (builtins.readFile ./index.md);
  md.runvm = pkgs.substituteAll {
    src = ./runvm.md;
    result = artefacts.runvm;
    inherit (hypertext) runvm footer;
  };
  md.initrd = pkgs.substituteAll {
    src = ./initrd.md;
    result = artefacts.initrd;
    inherit (hypertext) footer;
  };
  md.kernel = pkgs.substituteAll {
    src = ./kernel.md;
    result = artefacts.kernel;
    inherit (hypertext) footer;
  };
  md.rootfs = pkgs.substituteAll {
    src = ./rootfs.md;
    result = artefacts.rootfs;
    inherit (hypertext) footer;
  };
  md.ext4 = pkgs.substituteAll {
    src = ./ext4.md;
    result = artefacts.ext4;
    inherit (hypertext) footer;
  };
  md.stage-1 = pkgs.substituteAll {
    src = ./stage-1.md;
    result = artefacts.stage-1;
    inherit (hypertext) footer;
  };
  md.stage-2 = pkgs.substituteAll {
    src = ./stage-2.md;
    result = artefacts.stage-2;
    inherit (hypertext) footer;
  };
  md.dist = pkgs.substituteAll {
    src = ./dist.md;
    result = artefacts.dist;
    inherit (hypertext) footer;
  };
  md.extra-utils = pkgs.substituteAll {
    src = ./extra-utils.md;
    result = artefacts.extra-utils;
    inherit (hypertext) footer;
  };
  md.path = pkgs.substituteAll {
    src = ./path.md;
    result = artefacts.path;
    inherit (hypertext) footer;
  };
  md.shrunk = pkgs.substituteAll {
    src = ./shrunk.md;
    result = artefacts.shrunk;
    inherit (hypertext) footer;
  };
  md.toplevel = pkgs.substituteAll {
    src = ./toplevel.md;
    result = artefacts.toplevel;
    inherit (hypertext) footer;
  };
  md.boot = pkgs.substituteAll {
    src = ./boot.md;
    result = artefacts.boot;
    inherit (hypertext) footer;
  };
  md.raw = pkgs.substituteAll {
    src = ./raw.md;
    result = artefacts.raw;
    inherit (hypertext) footer;
  };
  md.qcow2 = pkgs.substituteAll {
    src = ./qcow2.md;
    result = artefacts.qcow2;
    inherit (hypertext) footer;
  };
  md.syslinux = pkgs.substituteAll {
    src = ./syslinux.md;
    result = artefacts.syslinux;
    inherit (hypertext) footer;
  };
  md.default = pkgs.runCommand "default.md" {} ''
    echo '---' > $out
    echo 'title: not-os' >> $out
    echo '---' >> $out
    echo >> $out
    echo '`default.nix`' >> $out
    echo >> $out
    echo '<pre><code>' >> $out
    sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' ${source.default} \
      | nl --number-width 2 --number-format rz --body-numbering a >> $out
    echo '</code></pre>' >> $out
    echo '${hypertext.footer}' >> $out
  '';
  md.cmdline = pkgs.substituteAll {
    src = ./cmdline.md;
    result = artefacts.cmdline;
    inherit (hypertext) footer;
  };
  md.root-modules = pkgs.substituteAll {
    src = ./root-modules.md;
    result = artefacts.root-modules;
    inherit (hypertext) footer;
  };
  md.todo = pkgs.substituteAll {
    src = ./todo.md;
    inherit (hypertext) footer;
  };
  md.digital-ocean = pkgs.substituteAll {
    src = ./digital-ocean.md;
    inherit (hypertext) footer;
  };

  all = pkgs.runCommand "all" {} ''
    mkdir $out
    cp ${md.index} $out/index.md
    cp ${md.runvm} $out/runvm.md
    cp ${md.kernel} $out/kernel.md
    cp ${md.initrd} $out/initrd.md
    cp ${md.rootfs} $out/rootfs.md
    cp ${md.ext4} $out/ext4.md
    cp ${md.stage-1} $out/stage-1.md
    cp ${md.stage-2} $out/stage-2.md
    cp ${md.dist} $out/dist.md
    cp ${md.extra-utils} $out/extra-utils.md
    cp ${md.path} $out/path.md
    cp ${md.shrunk} $out/shrunk.md
    cp ${md.toplevel} $out/toplevel.md
    cp ${md.boot} $out/boot.md
    cp ${md.raw} $out/raw.md
    cp ${md.qcow2} $out/qcow2.md
    cp ${md.syslinux} $out/syslinux.md
    cp ${md.cmdline} $out/cmdline.md
    cp ${md.root-modules} $out/root-modules.md
    cp ${md.todo} $out/todo.md
    cp ${md.digital-ocean} $out/digital-ocean.md
  '';
}
