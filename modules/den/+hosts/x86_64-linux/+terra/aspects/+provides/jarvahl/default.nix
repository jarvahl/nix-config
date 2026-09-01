{ den
, lib
, ...
}:
{
  den.aspects.terra = lib.mkMerge [
    {
      provides.jarvahl = {
        nvim = { ... }: {
          theme = {
            name = "oxocarbon";
            style = "dark";
          };
        };

        tmux = { ... }: {
          initConfig = lib.mkAfter ''
            set -g status-style "bg=#161616,fg=#f2f4f8"
            set -g status-left "#[fg=#3ddbd9,bold] #S"
            set -g status-right "#[fg=#42be65] #(whoami)#[fg=#525252]@#[fg=#78a9ff]#H"

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

        zsh = { ... }: {
          initConfig = lib.mkAfter ''
            export EZA_COLORS="di=1;38;2;51;177;255:ex=1;38;2;66;190;101:fi=38;2;242;244;248:ln=38;2;61;219;217:or=38;2;238;83;150:ur=38;2;255;126;182:uw=38;2;255;233;123:ux=38;2;66;190;101:gr=38;2;120;169;255:gw=38;2;255;233;123:gx=38;2;66;190;101:tr=38;2;238;83;150:tw=38;2;255;233;123:tx=38;2;66;190;101:*.nix=38;2;61;219;217:*.md=38;2;120;169;255:*.json=38;2;255;233;123:*.toml=38;2;61;219;217:*.kdl=38;2;61;219;217"

            ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#525252"
            zstyle ':fzf-tab:*' fzf-flags --color=fg:#f2f4f8,bg:#161616,hl:#3ddbd9,fg+:#ffffff,bg+:#262626,hl+:#78a9ff,prompt:#3ddbd9,pointer:#ee5396,marker:#42be65,spinner:#3ddbd9,header:#525252

            PROMPT=$'%B%{\e[38;2;61;219;217m%}#%{\e[0m%}%b '
          '';
        };

        hjem = { pkgs, ... }: {
          packages = with pkgs;
            [
              wget
              curl
              firefox
              gh
            ];
        };

        nixos =
          { config, ... }:
          let
            passwordSecret = "users/jarvahl/hashedPassword";
          in
          {
            sops.secrets.${passwordSecret}.neededForUsers = true;

            users.users.jarvahl.hashedPasswordFile = config.sops.secrets.${passwordSecret}.path;

            services.openssh.settings.AllowUsers = [ "jarvahl" ];
          };

        includes =
          [
            den.aspects.development
            den.batteries.primary-user
            (den.batteries.user-shell "zsh")
          ];
      };
    }

    {
      provides.jarvahl.hjem = { pkgs, ... }: {
        packages = [ pkgs.codex ];
      };
    }
  ];
}
