---
title: not-os
---

## runvm

```
$ nix-build -A runvm
@result@
```

runvm is the main derivation of not-os. It is defined in
[`default.nix`](default.html). Every other derivation is a dependency.

The result is (a symlink to) a script calling qemu-kvm with the right
parameters, in particular the kernel &#x24B6;, the initrd &#x24B7;, and the
rootfs &#x24B8;.

<pre><code>
@runvm@
</code></pre>

*Note: artifial newlines added.*

A kernel command line &#x24B9; is used to let the stage-1 know about the
location of toplevel;


### Example execution

Executing the resulting script looks like:

```
$ ./result
[...]
<<< NotOS Stage 2 >>>

setting up /etc...
- runit: $Id: 25da3b86f7bed4038b8a039d2f8e8c9bbcf0822b $: booting.
- runit: enter stage: /etc/runit/1
 3 Nov 10:59:00 ntpdate[106]: no servers can be used, exiting
- runit: leave stage: /etc/runit/1
- runit: enter stage: /etc/runit/2
1.97 0.01
```

You can type `ctrl-a x` to quit. You can also enter the QEMU monitor with
`ctrl-a c`, then e.g. type `screendump filename.ppm` to capture an image like
the one in the test, then `quit` to terminate QEMU.


<br />
@footer@
