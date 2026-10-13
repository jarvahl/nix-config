{ lib, ... }:

{
  den.aspects.worktrunk.hjem =
    { pkgs, ... }:
    let
      shellIntegration = pkgs.runCommand "worktrunk-zsh-integration" { } ''
        plugin_dir=$out/share/zsh/plugins/worktrunk
        mkdir -p "$plugin_dir"
        ${lib.getExe pkgs.worktrunk} config shell init zsh > "$plugin_dir/worktrunk.plugin.zsh"
      '';
    in
    {
      packages = [ pkgs.worktrunk ];
      rum.programs.zsh.initConfig = ''
        source "${shellIntegration}/share/zsh/plugins/worktrunk/worktrunk.plugin.zsh"
      '';
    };
}
