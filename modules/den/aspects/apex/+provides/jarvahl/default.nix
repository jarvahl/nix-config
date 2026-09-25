{ den, lib, ... }:
lib.mkMerge [
  {
    den.aspects.apex.provides.jarvahl.includes = [
      den.aspects.development
      den.batteries.primary-user
      (den.batteries.user-shell "zsh")
    ];
  }

  {
    den.aspects.apex.provides.jarvahl.hjem = { pkgs, ... }: {
      packages = [ pkgs.google-chrome ];
    };

    den.aspects.apex.provides.jarvahl.includes = [
      (den.batteries.unfree [ "google-chrome" ])
    ];
  }

  {
    den.aspects.apex.provides.jarvahl.hjem = { pkgs, ... }: {
      packages = [ pkgs.codex ];
    };
  }

  {
    den.aspects.apex.provides.jarvahl.hjem = { pkgs, ... }: {
      packages = [ pkgs.firefox ];
    };
  }

  {
    den.aspects.apex = {
      provides.jarvahl = {
        hjem = { pkgs, ... }: {
          files.".config/foot/foot.ini".text = ''
            [main]
            pad=16x16
            font=FiraCode Nerd Font:size=9
          '';

          packages = [ pkgs.foot ];
        };
      };
    };
  }

  {
    den.aspects.apex.provides.jarvahl = {
      hjem = { pkgs, ... }: {
        packages = [ pkgs.gh ];
      };

      nixos = { config, ... }: {
        sops.secrets = {
          "users/jarvahl/github/username" = { };
          "users/jarvahl/github/email" = { };
        };

        sops.templates."github-identity" = {
          content = ''
            [user]
                name = ${config.sops.placeholder."users/jarvahl/github/username"}
                email = ${config.sops.placeholder."users/jarvahl/github/email"}
          '';
          owner = "jarvahl";
          mode = "0400";
        };

        sops.templates."github-include" = {
          content = ''
            [includeIf "hasconfig:remote.*.url:https://github.com/"]
                path = ~/.config/git/github-identity
          '';
          owner = "jarvahl";
          mode = "0400";
        };

        hjem.users.jarvahl = {
          files = {
            ".config/git/github-identity".source = config.sops.templates."github-identity".path;
            ".config/git/github-include".source = config.sops.templates."github-include".path;
          };

          rum.programs.git.settings.include.path = "~/.config/git/github-include";
        };
      };
    };
  }

  {
    den.aspects.apex = {
      provides.jarvahl = {
        hjem =
          { pkgs, ... }:
          let
            gnome = pkgs.writeShellApplication {
              name = "gnome";
              runtimeInputs = [ pkgs.systemd ];
              text = ''
                systemctl --user start nested-gnome.service
              '';
            };

            nestedGnome = pkgs.writeShellApplication {
              name = "nested-gnome";
              runtimeInputs = with pkgs; [
                dbus
                gnome-shell
                coreutils
              ];
              excludeShellChecks = [ "SC2016" ];
              text = ''
                  inner_display=gnome-nested-0
                  outer_display="''${WAYLAND_DISPLAY:?nested-gnome requires an existing Wayland session}"

                exec dbus-run-session -- ${pkgs.runtimeShell} -c '
                  inner_display="$1"
                  outer_display="$2"

                  WAYLAND_DISPLAY="$outer_display" ${pkgs.gnome-shell}/bin/gnome-shell \
                    --wayland \
                    --no-x11 \
                    --wayland-display="$inner_display" &
                  shell_pid=$!

                  socket="''${XDG_RUNTIME_DIR:?}/$inner_display"
                  for _ in $(${pkgs.coreutils}/bin/seq 1 100); do
                    [ -S "$socket" ] && break
                    kill -0 "$shell_pid" 2>/dev/null || wait "$shell_pid"
                    ${pkgs.coreutils}/bin/sleep 0.1
                  done

                  if [ ! -S "$socket" ]; then
                    kill "$shell_pid" 2>/dev/null || true
                    wait "$shell_pid" 2>/dev/null || true
                    echo "nested-gnome: inner Wayland socket did not appear" >&2
                    exit 1
                  fi

                  WAYLAND_DISPLAY="$inner_display" \
                    ${pkgs.dbus}/bin/dbus-update-activation-environment WAYLAND_DISPLAY

                  wait "$shell_pid"
                ' nested-gnome "$inner_display" "$outer_display"
              '';
            };
          in
          {
            packages = [ gnome ];

            systemd.services.nested-gnome = {
              description = "Nested GNOME Shell compositor";
              partOf = [ "wayland-session@hyprland\\x2duwsm.desktop.target" ];
              after = [ "wayland-session@hyprland\\x2duwsm.desktop.target" ];

              serviceConfig = {
                ExecStart = "${nestedGnome}/bin/nested-gnome";
                Restart = "no";
              };
            };
          };
      };
    };
  }

  {
    den.aspects.apex.provides.jarvahl = {
      hjem =
        { pkgs, ... }:
        {
          files.".config/hyprcage/config.toml".source = pkgs.writeText "hyprcage-config.toml" ''
            [screen]
            width = 1280
            height = 800
            max_width = 3840
            max_height = 2160
            max_per_session = 4
            mirror = true
            notify = true

            [workspaces]
            mirror = [6, 9]

            [mirror]
            group = "session"
            per_workspace = 4
            fps = 30

            [lifecycle]
            safety_timer = "15m"

            [cage]
            renderer = "auto"
            render_device = ""
          '';

          programs.mcp.servers.hyprcage = {
            command = "${pkgs.hyprcage}/bin/hyprcage";
            args = [ "mcp" ];
            lifecycle = "lazy";
          };

          programs.pi = {
            extraPackages = [ pkgs.hyprcage ];
            skills.hyprcage = "${pkgs.hyprcage}/share/hyprcage/skills/hyprcage";
          };
        };

      nixos = { pkgs, ... }: {
        environment.systemPackages = [
          pkgs.cage
          pkgs.hyprcage
        ];
      };
    };
  }

  {
    den.aspects.apex = {
      provides.jarvahl.hjem = { config, pkgs, ... }: {
        packages = [ pkgs.hypridle ];

        files.".config/hypr/hypridle.conf".source = pkgs.writeText "hypridle.conf" ''
          listener {
            timeout = 600
            on-timeout = ${pkgs.hyprland}/bin/hyprctl dispatch dpms off
            on-resume = ${pkgs.hyprland}/bin/hyprctl dispatch dpms on
          }
        '';

        systemd.services.hypridle = {
          description = "Hyprland idle manager";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          wants = [ "wayland-session-waitenv.service" ];
          after = [ "wayland-session-waitenv.service" ];
          restartTriggers = [ config.files.".config/hypr/hypridle.conf".source ];

          serviceConfig = {
            ExecStart = "${pkgs.hypridle}/bin/hypridle -c ${config.files.".config/hypr/hypridle.conf".source}";
            Restart = "on-failure";
          };
        };
      };
    };
  }

  {
    den.aspects.apex.provides.jarvahl.hjem = { pkgs, ... }: {
      packages = [ pkgs.jujutsu ];
    };
  }

  {
    den.aspects.apex.provides.jarvahl.hjem = { pkgs, ... }: {
      packages = [ pkgs.openspec ];
    };
  }

  {
    den.aspects.apex.provides.jarvahl = {
      nixos =
        { config, ... }:
        let
          passwordSecret = "users/jarvahl/hashedPassword";
        in
        {
          sops.secrets.${passwordSecret}.neededForUsers = true;
          sops.secrets."users/jarvahl/github/ssh-key" = {
            owner = "jarvahl";
            mode = "0400";
          };
          users.users.jarvahl.hashedPasswordFile = config.sops.secrets.${passwordSecret}.path;
          services.openssh.settings.AllowUsers = [ "jarvahl" ];
        };

      hjem = { sops, ... }: {
        files.".ssh/config.d/github".text = ''
          Host github.com
            HostName github.com
            User git
            IdentityFile ${sops.secrets."users/jarvahl/github/ssh-key".path}
            IdentitiesOnly yes
        '';
      };
    };
  }

  {
    den.aspects.apex = {
      provides.jarvahl = {
        hjem = { pkgs, ... }: {
          packages = [ pkgs.swaybg ];

          systemd.services.swaybg = {
            description = "Hyprland background";
            wantedBy = [ "graphical-session.target" ];
            partOf = [ "graphical-session.target" ];
            wants = [ "wayland-session-waitenv.service" ];
            after = [ "wayland-session-waitenv.service" ];

            serviceConfig = {
              ExecStart = "${pkgs.swaybg}/bin/swaybg -c '#c8c0b4'";
              Restart = "on-failure";
            };
          };
        };
      };
    };
  }

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

        set -g window-status-format "#{?#{==:#{@pi_window_status},unread},#[fg=#f2c94c],#[fg=#525252]}#I:#W#[default]  "
        set -g window-status-current-format "#{?#{==:#{@pi_window_status},unread},#[fg=#f2c94c],#[fg=#3ddbd9]}#I:#W#[default]  "
        set -g window-status-activity-style "fg=#ff7eb6,bold"

        set -g pane-border-style "fg=#262626"
        set -g pane-active-border-style "fg=#3ddbd9"
        set -g display-panes-colour "#78a9ff"
        set -g display-panes-active-colour "#3ddbd9"

        set -g message-style "bg=#262626,fg=#f2f4f8"
        set -g message-command-style "bg=#262626,fg=#3ddbd9"
        set -g mode-style "bg=#393939,fg=#ffffff"
        set -g tree-mode-selection-style "bg=#262626,fg=#3ddbd9,bold"
      '';
    };
  }

  {
    den.aspects.apex.provides.jarvahl.hjem = {
      rum.programs.zsh.initConfig = lib.mkAfter ''
        export EZA_COLORS="di=1;38;2;51;177;255:ex=1;38;2;66;190;101:fi=38;2;242;244;248:ln=38;2;61;219;217:or=38;2;238;83;150:ur=38;2;255;126;182:uw=38;2;255;233;123:ux=38;2;66;190;101:gr=38;2;120;169;255:gw=38;2;255;233;123:gx=38;2;66;190;101:tr=38;2;238;83;150:tw=38;2;255;233;123:tx=38;2;66;190;101:*.nix=38;2;61;219;217:*.md=38;2;120;169;255:*.json=38;2;255;233;123:*.toml=38;2;61;219;217:*.kdl=38;2;61;219;217"

        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#525252"
        zstyle ':fzf-tab:*' fzf-flags --color=fg:#f2f4f8,bg:#161616,hl:#3ddbd9,fg+:#ffffff,bg+:#262626,hl+:#78a9ff,prompt:#3ddbd9,pointer:#ee5396,marker:#42be65,spinner:#3ddbd9,header:#525252

        PROMPT=$'%B%{\e[38;2;61;219;217m%}#%{\e[0m%}%b '
      '';
    };
  }
]
