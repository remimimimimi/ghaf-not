{supportedSystems ? ["x86_64-linux" "i686-linux"]}:
with import <nixpkgs/lib>; {
  tests.boot = import tests/boot.nix {system = "x86_64-linux";};
}
