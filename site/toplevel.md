---
title: not-os
---

## toplevel

```
$ nix-build -A toplevel
@result@
```

The toplevel contains two scripts and a directory (actually a symlink):

```
$ ls /nix/store/q40j6y70nwhgazvhzrlzh79cjlfik7jv-not-os/
activate  init  sw
```

- `activate` content is the value of `config.system.activationScripts.script`.
  In particular it calls the `setup-etc.pl` script.
- `init` content is the value of `stage-2`, which is
  `stage-2-init.sh`, with `systemConfig` replaced by toplevel's path, and
  `sw/bin/` set as its `$PATH`.
  The `init` script mounts a few special filesystems, calls the `activate`
  script, then execute `runit.
- `sw` is a symlink to `path`, which contains only a `bin/` directory with
  symlinks to base executables (e.g. `[`, `nix-build`, `yes`, ...).

The toplevel is packaged as a squashfs image.

The toplevel's path is sometimes called `systemConfig` or `sysconfig`.


<br />
@footer@
