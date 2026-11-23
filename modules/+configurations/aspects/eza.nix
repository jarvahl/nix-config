{ lib, ... }:

{
  den.aspects.eza.hjem =
    { pkgs, ... }:
    let
      flags = "--group-directories-first --icons=always";
    in
    {
      packages = [ pkgs.eza ];
      rum.programs.zsh.initConfig = ''
        alias ls="${lib.getExe pkgs.eza} ${flags}"
        alias ll="${lib.getExe pkgs.eza} -lh ${flags}"
        alias la="${lib.getExe pkgs.eza} -la ${flags}"
        alias tree="${lib.getExe pkgs.eza} --tree ${flags}"
      '';
    };
}
