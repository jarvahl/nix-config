{ inputs, ... }:
{
  den.aspects.tmux.hjem = { ... }: {
    programs.tmux = {
      enable = true;
      mouse = true;

      extraConfig = ''
        set -g status off
        set -g history-limit 10000
        set -g base-index 1
        setw -g pane-base-index 1
      '';
    };
  };

  den.default.nixos.hjem.extraModules = [
    (inputs.home-manager + "/modules/programs/tmux.nix")
  ];
}
