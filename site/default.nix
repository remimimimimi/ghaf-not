# This is a set of derivations to create markdown files to document not-os.
# The derivations here use actual parts of the not-os derivations.
#
# Example build instruction:
#  nix-build site/ -A md.runvm

{ configuration ? import ../configuration.nix
, nixpkgs ? <nixpkgs>
, extraModules ? []
, system ? builtins.currentSystem
}:

let
  pkgs = import nixpkgs { inherit system; config = {}; };
  artefacts = import ../default.nix
    { inherit configuration nixpkgs extraModules system; };
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
's@\(.{config.system.build.squashfs}\),@<a href=squashfs.html>\1 \&#x24B8,\n    </a>@' \
-e \
's@\(.{toString config.boot.kernelParams}\)@<a href=squashfs.html>\1 \&#x24B9\n   </a>@' \
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

  all = pkgs.runCommand "all" {} ''
    mkdir $out
    cp ${md.index} $out/index.md
    cp ${md.runvm} $out/runvm.md
    cp ${md.initrd} $out/initrd.md
    cp ${md.default} $out/default.md
  '';
}
