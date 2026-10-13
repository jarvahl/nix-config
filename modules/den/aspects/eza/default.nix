{ lib, ... }:

{
  den.aspects.eza.homeManager =
    { pkgs, ... }:
    let
      flags = "--group-directories-first --icons=always";
    in
    {
      home.packages = [ pkgs.eza ];
      programs.zsh.initContent = ''
        alias ls="${lib.getExe pkgs.eza} ${flags}"
        alias ll="${lib.getExe pkgs.eza} -lh ${flags}"
        alias la="${lib.getExe pkgs.eza} -la ${flags}"
        alias tree="${lib.getExe pkgs.eza} --tree ${flags}"
      '';
    };
}
