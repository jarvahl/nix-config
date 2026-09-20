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
      pkgs.nodejs
    ];

    files.".local/state/herdr/plugins/hhdebb.herdr-radar".source = pkgs.herdr-radar;
    files.".local/state/herdr/plugins/worktrunk".source = pkgs.herdr-worktrunk;
    files.".config/herdr/plugins.json".text = builtins.toJSON [
      {
        plugin_id = "hhdebb.herdr-radar";
        name = "Herdr Radar";
        version = "1.3.9";
        min_herdr_version = "0.9.0";
        description = "Who's working, who's waiting on you";
        manifest_path = "${pkgs.herdr-radar}/herdr-plugin.toml";
        plugin_root = pkgs.herdr-radar;
        enabled = true;
        platforms = [ "linux" "macos" "windows" ];
        source.kind = "local";
      }
      {
        plugin_id = "worktrunk";
        name = "Worktrunk";
        version = "0.1.0";
        min_herdr_version = "0.7.0";
        description = "Switch, create, remove, or merge git worktrees via worktrunk";
        manifest_path = "${pkgs.herdr-worktrunk}/herdr-plugin.toml";
        plugin_root = pkgs.herdr-worktrunk;
        enabled = true;
        platforms = [ "macos" "linux" ];
        source.kind = "local";
      }
    ];
    files.".config/herdr/plugins/config/hhdebb.herdr-radar/config.toml".text = ''
      agents_panel = "plugin"
      order = "active"
      variant = "dark"
      done_hold = "until_seen"
      blocked_hold = true
      idle_grace_seconds = 2.5
      activity_fresh_minutes = 15
      activity_stale_minutes = 120
      group_indent = 2
      group_gap = true
      show_tab = false
      trim_group_prefix = true
      follow_appearance = false
    '';

    files.".config/herdr/plugins/config/worktrunk/config.toml".text = ''
      open_mode = "workspace"
    '';
  };
}
