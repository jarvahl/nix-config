{ lib, ... }:

{
  den.aspects.bat.homeManager = { pkgs, ... }: {
    home.packages = [ pkgs.bat ];
    programs.zsh.initContent = ''
      alias cat='${lib.getExe pkgs.bat}'
    '';
  };
}
