---
title: not-os
---


not-os is a minimal OS based on the Linux kernel, coreutils, runit, and Nix. It
is also the build script, written in Nix expressions, to build such OS.

This is a project of Michael Bishop (cleverca22 on GitHub, clever on IRC). I
modified it just a bit to make it possible to generate this documentation.

As a build tool, not-os uses nixpkgs and in particular the [NixOS module
system](https://nixos.wiki/wiki/NixOS_Modules) to build the three main
components of a Linux-based operating system:

- a kernel (`config.system.build.kernel`)
- an initrd (`config.system.build.initialRamdisk`)
- a rootfs (`config.system.build.squashfs`)

Given the three above derivations, it is possible to generate the appropriate
qemu-kvm invocation as a script, [runvm](runvm.html). runvm is the main entry
point to start playing and understanding not-os. Follow the link, and enjoy!

<br />
<br />
*To follow along, you can clone the Git repository and run each `nix-build`
command as they appear at the top of each page.*


<hr />


<div class="mv5 flex-ns">
<section class="w-40-ns pr4 mb5">
<h1 class="f5 ttu lh-title mb3">Intro</h1>
<ul class="list pa0 ma0 lh-copy">
  <li class=mr4><a href="/projects/not-os/index.html">not-os</a>
</ul>
</section>
<section class="w-70-ns pr4 mb5">
<h1 class="f5 ttu lh-title mb3">Main attributes</h1>
<ul class="list pa0 ma0 lh-copy">
  <li class=mr4><a href="/projects/not-os/runvm.html">runvm</a>
  <li class=mr4><a href="/projects/not-os/kernel.html">kernel</a>
  <li class=mr4><a href="/projects/not-os/initrd.html">initrd</a>
  <li class=mr4><a href="/projects/not-os/rootfs.html">rootfs</a>
  <li class=mr4><a href="/projects/not-os/stage-1.html">stage-1</a>
  <li class=mr4><a href="/projects/not-os/stage-2.html">stage-2</a>
  <li class=mr4><a href="/projects/not-os/dist.html">dist</a>
  <li class=mr4><a href="/projects/not-os/extra-utils.html">extra-utils</a>
  <li class=mr4><a href="/projects/not-os/path.html">path</a>
  <li class=mr4><a href="/projects/not-os/shrunk.html">shrunk</a>
  <li class=mr4><a href="/projects/not-os/toplevel.html">toplevel</a>
</ul>
</section>
<section class="w-40-ns pr4 mb5">
<h1 class="f5 ttu lh-title mb3">Source</h1>
<ul class="list pa0 ma0 lh-copy">
  <li class=mr4><a href="/projects/not-os/default.html">default.nix</a>
</ul>
</section>
<section class="w-70-ns pr4 mb5">
<h1 class="f5 ttu lh-title mb3">Results</h1>
<ul class="list pa0 ma0 lh-copy">
  <li class=mr4><a href="/projects/not-os/index.html">iyyf9-runvm</a>
</ul>
<br />
<h1 class="f5 ttu lh-title mb3">Values</h1>
<ul class="list pa0 ma0 lh-copy">
  <li class=mr4><a href="/projects/not-os/cmdline.html">cmdline</a>
  <li class=mr4><a href="/projects/not-os/root-modules.html">root-modules</a>
</ul>
</section>
</div>
