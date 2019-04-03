---
title: not-os
---

## TODO

- digitalocean page with explanation of how to upload the qcow2 image (gzipped)
  then create a droplet (using doctl).

- On Digital Ocean, use the public SSH key provided in the config-2 disk.

- note somewhere this: if an attribute build causes this error

```
cp: cannot create regular file '/nix/store/dgv0n0k4a43xz5bwfwvdmvgfn46ksc94-all/ext4.md': Permission denied
```

  this can be caused by creating (with `cp`) twice the same file in `$out`.


Help would be appreciated for a few things:

- Create a bootable EXT4 partition without using root privilege or mount.
  This would allow to create an image running on Digital Ocean with a normal
Nix attribute instead of the special make-qcow2.sh script.

- Allow to reference the site derivation directly within the image definition.
  I didn't manage to do it because this creates a recursive definition (the
image depends on the site which use the image result paths to embed them in the
documentation). Currently I'm using an impure `/var/www` path to break the
cycle.

- Support S6 in addition of runit.

- Try to reuse the Nginx NixOS module to craft its configuration. The problem
  is that NixOS modules assume a lot (e.g. systemd units).

- There is a lot of repetition in `site/default.nix`.

- Creating the actual HTML pages is done out of this repository. I'd like to
  generate them directly here, possibly with a DocBook toolchain.

- Add fcron. Use it to renew certificates.

- Have something like `nixos-rebuild switch` working. It would be great to have
  an almost empty VM starting with just the ability to nix-build its
  configuration (provided through config-2 user-data).

  Currently Digital Ocean has a big shortcoming: it is not possible to assign a
  floating IP to a VM created from a custom image. The only documented way to
  keep an IP, is to rebuild an existing VM. But it is actually not possible
  because custom images are not proposed on the rebuild screen. This means that
  nixos-rebuild is a must have.

- The import of `qemu.nix` in the configuration maybe not necessary on Digital
  Ocean.

- nixpkgs offers multiple ACME implementations. I'm using dehydrated, wich is a
  Bash script. (I don't want to rely on Python for that. There is a Go
  implementation but building its derivation started to compile a lot of things
  and I stopped it. I couldn't get acme.sh run).

  After renewing a certificate, Nginx can be reloaded as follow:

```
#! ${pkgs.stdenv.shell}
${pkgs.nginx}/bin/nginx -s reload -c ${nginx_config}
```

  I plan to use two Nginx instances: one for serving HTTP, in particular the
  .well-known route used by ACME, and the other to serve HTTPS.

  A difficulty by using the same instance is that it can't contain the
  configuration of the HTTPS part as long as the certificates or not in place:
  Nginx wouldn't start at all, preventing to serve the .well-known directory too.

  The fact that obtaining a certificate makes use of a HTTP server is a detail
  that I would rather prefer abstracted away of the main HTTPS server.
  Indeed it is possible to obtain a certificate in other way.

  This means that instead of editing the configuration of a running instance
  and reloading it, the second service is broken until the first one does its
  job.

- I don't like the http challenge and would prefer to use the dns-based
  challenge to acquire a certificate (the machine should already be running a
  web server, already be assigned the domain, and actually use HTTP, before
  requesting the certificcate).
