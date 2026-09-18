{ ... }:
{
  tmux.modules = [
    ({ config, lib, pkgs, ... }:
      {
        options.persistence.enable = lib.mkEnableOption "tmux session persistence" // { default = true; };

        config = {
          rc = lib.mkIf config.persistence.enable (lib.mkBefore ''
            # Session persistence. Initial restore is performed by systemd.
            set -g @resurrect-dir "~/.local/state/tmux/resurrect"
            set -g @resurrect-capture-pane-contents "on"
            set -g @continuum-save-interval "1"
            set -g @continuum-restore "off"
            run-shell '${pkgs.tmuxPlugins.sensible}/share/tmux-plugins/sensible/sensible.tmux'
            run-shell '${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/resurrect.tmux'
            run-shell '${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/continuum.tmux'
          '');

          packages = [ pkgs.tmux ] ++ lib.optionals config.persistence.enable [
            pkgs.tmuxPlugins.resurrect
            pkgs.tmuxPlugins.continuum
          ];
        };
      })
  ];
}
