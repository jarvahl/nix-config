{ lib, ... }:

{
  den.aspects.worktrunk.homeManager =
    { pkgs, ... }:
    let
      shellIntegration = pkgs.runCommand "worktrunk-zsh-integration" { } ''
        plugin_dir=$out/share/zsh/plugins/worktrunk
        mkdir -p "$plugin_dir"
        ${lib.getExe pkgs.worktrunk} config shell init zsh > "$plugin_dir/worktrunk.plugin.zsh"
      '';
    in
    {
      home.packages = [ pkgs.worktrunk ];
      programs.zsh.initContent = ''
        source "${shellIntegration}/share/zsh/plugins/worktrunk/worktrunk.plugin.zsh"
      '';
    };
}
