{ ... }:
{
  den.aspects.apex.provides.jarvahl.hjem = { pkgs, ... }: {
    programs.herdr = {
      enable = true;
      integrations.pi.enable = true;
      extraConfig = ''
        [[keys.command]]
        key = "prefix+shift+g"
        type = "plugin_action"
        command = "worktrunk.open"
        description = "Worktree: switch or create"
      '';
    };

    packages = [ pkgs.herdr-worktrunk ];

    files.".local/state/herdr/plugins/worktrunk".source = pkgs.herdr-worktrunk;
    files.".config/herdr/plugins/config/worktrunk/config.toml".text = ''
      open_mode = "workspace"
    '';
  };
}
