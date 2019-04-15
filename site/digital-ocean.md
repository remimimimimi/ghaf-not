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

- Digital Ocean supports only EXT3 and EXT4 file systems in their custom image
  feature.

- Normally `cloud-init` should be used. Currently the generated image only
  supports requesting an IP address using `dhcpcd`.

- The console logs show some possible problem related to `rngd`. I think I
  should run `haveged`.

- When running `blkid` during the boot process on Digital Ocean, one can see

```
/dev/vdb: LABEL="config-2" TYPE="iso9660"
/dev/vda1: LABEL="rootfs" UUID="..." TYPE="ext4"
```

- The `config-2` drive is the configuration disk intended for cloud-init.

- When I tried to run `dhcpcd` in the `runit` `1` script, I saw an error like

    ```
    dhcp_openpbf: Address family not supported by protocol
    ```

    The solution was to load the `af_packet` kernel module.

- The `doctl` tool doesn't currently seem to support the upload of custom
  images.

- Currently Digital Ocean has a big shortcoming: it is not possible to assign a
  floating IP to a VM created from a custom image. The only documented way to
  keep an IP, is to rebuild an existing VM. But it is actually not possible
  because custom images are not proposed on the rebuild screen. This means that
  nixos-rebuild is a must have.

- Once the isofs kernel module is loaded, it is possible to mount the config-2
  drive:

    ```
    -bash-4.4# blkid
    /dev/vda1: LABEL="rootfs" UUID=".." TYPE="ext4" PARTUUID="20000000-01"
    /dev/vdb: UUID="2019-04-13-09-08-27-00" LABEL="config-2" TYPE="iso9660
    ```

    ```
    -bash-4.4# mkdir /mnt
    -bash-4.4# mount /dev/vdb /mnt
    mount: /mnt: WARNING: device write-protected, mounted read-only.
    -bash-4.4# ls /mnt/
    digitalocean_meta_data.json  openstack
    ```

    The three openstack directories have identical content:

    ```
    -bash-4.4# sha1sum /mnt/openstack/latest/*
    96f6d38846239ade3f965e1a35386919eae6d5ce  /mnt/openstack/latest/meta_data.json
    472c2b3220721e376aa870c6d68ae5110ef78b1a  /mnt/openstack/latest/network_data.json
    da39a3ee5e6b4b0d3255bfef95601890afd80709  /mnt/openstack/latest/user_data
    c82748155cc4abc84e30e158a24e11fe577cc63f  /mnt/openstack/latest/vendor_data.json
    -bash-4.4# sha1sum /mnt/openstack/2012-08-10/*
    96f6d38846239ade3f965e1a35386919eae6d5ce  /mnt/openstack/2012-08-10/meta_data.json
    472c2b3220721e376aa870c6d68ae5110ef78b1a  /mnt/openstack/2012-08-10/network_data.json
    da39a3ee5e6b4b0d3255bfef95601890afd80709  /mnt/openstack/2012-08-10/user_data
    c82748155cc4abc84e30e158a24e11fe577cc63f  /mnt/openstack/2012-08-10/vendor_data.json
    -bash-4.4# sha1sum /mnt/openstack/2015-10-16/*
    96f6d38846239ade3f965e1a35386919eae6d5ce  /mnt/openstack/2015-10-16/meta_data.json
    472c2b3220721e376aa870c6d68ae5110ef78b1a  /mnt/openstack/2015-10-16/network_data.json
    da39a3ee5e6b4b0d3255bfef95601890afd80709  /mnt/openstack/2015-10-16/user_data
    c82748155cc4abc84e30e158a24e11fe577cc63f  /mnt/openstack/2015-10-16/vendor_data.json
    ```

    The `digitalocean_meta_data.json` seems to combine the the openstack files
    (although with different names or structures).

    The part we're mostly interested in is the one with the SSH key to provision:

    ```
    -bash-4.4# cat /mnt/openstack/latest/meta_data.json
    {
      "admin_pass": "d624c3a16791b2997de776861b47de45",
      "availability_zone": "ams3",
      "instance_id": "129714139",
      "hostname": "not-os-config-2.qcow2.s-1vcpu-1gb-ams3-01",
      "public_keys": {
        "0": "ssh-rsa AAAA..."
      },
      "uuid": "129714139"
    }
    ```

    The public key, as set by the NixOS script, is at
    `/etc/ssh/authorized_keys.d/root`. We can just overwrite it.


<br />
@footer@
