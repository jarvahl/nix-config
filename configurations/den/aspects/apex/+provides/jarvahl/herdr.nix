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

        [[keys.command]]
        key = "prefix+a"
        type = "plugin_action"
        command = "hhdebb.herdr-radar.view-flip"
        description = "Herdr Radar: toggle view"

        [[keys.command]]
        key = "prefix+comma"
        type = "plugin_action"
        command = "hhdebb.herdr-radar.settings"
        description = "Herdr Radar: settings"
      '';
    };

    packages = [
      pkgs.herdr-radar
      pkgs.herdr-worktrunk
    ];

    files.".local/state/herdr/plugins/hhdebb.herdr-radar".source = pkgs.herdr-radar;
    files.".local/state/herdr/plugins/worktrunk".source = pkgs.herdr-worktrunk;
    files.".config/herdr/plugins/config/hhdebb.herdr-radar/config.toml".text = ''
      agents_panel = "plugin"
      order = "active"
      variant = "auto"
      done_hold = "until_seen"
      blocked_hold = true
      idle_grace_seconds = 2.5
      activity_fresh_minutes = 15
      activity_stale_minutes = 120
      group_indent = 2
      group_gap = true
      show_tab = false
      trim_group_prefix = true
      follow_appearance = true
    '';

    files.".config/herdr/plugins/config/worktrunk/config.toml".text = ''
      open_mode = "workspace"
    '';
  };
}
