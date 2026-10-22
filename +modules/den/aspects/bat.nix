{ lib, ... }:

{
  den.aspects.bat.hjem = { pkgs, ... }: {
    packages = [ pkgs.bat ];
    rum.programs.zsh.initConfig = ''
      alias cat='${lib.getExe pkgs.bat}'
    '';
  };
}
