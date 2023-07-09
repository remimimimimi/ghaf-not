{pkgs}: rec {
  writeInterpolatedFile = name: env: fn:
    pkgs.writeScript name (interpolateFile env fn);

  interpolateFile = env: fn:
    scopedImport env
    (builtins.toFile "quoted"
      ("''\n" + builtins.readFile fn + "''\n"));
}
