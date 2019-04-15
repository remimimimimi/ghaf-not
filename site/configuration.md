---
title: not-os
---

## Configuration


### Public SSH key

A public SSH key can be set at build time for the user `root`:

```
  environment.etc = {
    "ssh/authorized_keys.d/root" = {
      text = ''
ssh-rsa ...
      '';
      mode = "0444";
    };
  };
```

On Digital Ocean, the runit stage 1 script can set the key from the config-2
drive. Instead of setting a static key, set the `cloud-init` option to true:

```
  not-os.cloud-init = true;
```


<br />
@footer@
