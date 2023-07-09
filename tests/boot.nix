{system}:
with import <nixpkgs/nixos/lib/testing.nix> {inherit system;}; let
  config =
    (import ./.. {
      inherit system;
      extraModules = [./test-instrumentation.nix ../qemu.nix];
    })
    .config;
in {
  normalBoot = makeTest {
    name = "normal-boot";
    nodes = {};
    testScript = ''
      my $machine = createMachine({ qemuFlags => '-device virtio-rng-pci -kernel ${config.system.build.kernel}/bzImage -initrd ${config.system.build.initialRamdisk}/initrd -append "console=tty0 console=ttyS0 ${toString config.boot.kernelParams}" -drive index=0,id=drive1,file=${config.system.build.squashfs},readonly,media=cdrom,format=raw,if=virtio'});
      $machine->start;
      $machine->sleep(1);
      $machine->screenshot("test");
      $machine->shutdown;
    '';
  };
}
