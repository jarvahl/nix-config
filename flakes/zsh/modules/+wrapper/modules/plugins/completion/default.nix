{ ... }:
{
  zsh.modules = [
    ({ config, lib, ... }: {
      options.completion.enable = lib.mkEnableOption "zsh completion";

      config.zsh.rc = lib.mkIf config.completion.enable (lib.mkOrder 30 ''
        autoload -Uz compinit
        compinit
      '');
    })
  ];
}
