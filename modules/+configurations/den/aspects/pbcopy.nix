{
  den.aspects.pbcopy.hjem = { pkgs, ... }: {
    packages = [
      (pkgs.writeShellScriptBin "pbcopy" ''
        exec ${pkgs.wl-clipboard}/bin/wl-copy "$@"
      '')
    ];
  };
}
