{ lib, ... }:
{
  den.aspects.apex.provides.jarvahl.hjem = { pkgs, ... }: {
    nvf.vim.theme = {
      name = "oxocarbon";
      style = "dark";
    };

    tmux.initConfig = lib.mkAfter ''
      set -g status-style "bg=#161616,fg=#f2f4f8"
      set -g status-left "#[fg=#3ddbd9,bold] #S"
      set -g status-right "#[fg=#42be65] #(whoami)#[fg=#525252]@#[fg=#78a9ff]#H #(${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/scripts/continuum_save.sh)"

      set -g window-status-format "#[fg=#525252]  #I:#W  "
      set -g window-status-current-format "#[fg=#3ddbd9,bold]  #I:#W  "
      set -g window-status-activity-style "fg=#ff7eb6,bold"

      set -g pane-border-style "fg=#262626"
      set -g pane-active-border-style "fg=#3ddbd9"
      set -g display-panes-colour "#78a9ff"
      set -g display-panes-active-colour "#3ddbd9"

      set -g message-style "bg=#262626,fg=#f2f4f8"
      set -g message-command-style "bg=#262626,fg=#3ddbd9"
      set -g mode-style "bg=#393939,fg=#ffffff"
    '';
  };
}
