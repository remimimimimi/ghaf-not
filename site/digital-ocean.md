---
title: not-os
---

## Digital Ocean

```
$ ./make-qcow2.sh
...
```

The `make-qcow2.sh` script creates an image that boots with Digital Ocean
custom image feature.

This script is a work around the limitation of Digital Ocean not supporting the
FAT16 boot partition of the raw derivation. It is also not just a Nix attribute
in `default.nix` because I didn't find a way to built the same result without
using `sudo`, `losetup` or `mount`.

The resulting `image.qcow2` file can further be compressed with `gzip` and
uploaded to Digital Ocean.


### Notes

Digital Ocean supports only EXT3 and EXT4 file systems in their custom image
feature.

Normally `cloud-init` should be used. Currently there is only support to
request an IP address using `dhcpcd`.

The console logs show some possible problem related to `rngd`. I think I should
run `haveged`.

When running `blkid` during the boot process on Digital Ocean, one can see

```
/dev/vdb: LABEL="config-2" TYPE="iso9660"
/dev/vda1: LABEL="rootfs" UUID="..." TYPE="ext4"
```

The `config-2` drive is the configuration disk intended for cloud-init.

When I tried to run `dhcpcd` in the `runit` `1` script, I saw an error like

```
dhcp_openpbf: Address family not supported by protocol
```

The solution was to load the `af_packet` kernel module.

The `doctl` tool doesn't currently seem to support the upload of custom images.

<br />
@footer@
