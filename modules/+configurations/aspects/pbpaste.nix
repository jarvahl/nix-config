{
  den.aspects.pbpaste.hjem = { pkgs, ... }: {
    packages = [
      (pkgs.writeShellScriptBin "pbpaste" ''
        exec ${pkgs.wl-clipboard}/bin/wl-paste --no-newline "$@"
      '')
    ];
  };
}
