{ lib, den, ... }:
{
  den.aspects.tmux = {
    tmux = { pkgs, ... }: {
      initConfig = ''
        # Base options
        set -g mouse on
        set -g mode-keys vi
        set -g base-index 1
        setw -g pane-base-index 1
        set -g renumber-windows on
        set -g history-limit 50000
        set -g prefix2 Home

        # Window and pane splitting
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"
        unbind '"'
        unbind %
        bind c new-window -c "#{pane_current_path}"
        bind '"' split-window -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"

        # Status bar
        set -g status-position bottom
        set -g status on
        set -g status-interval 15
        set -g status-left "#[fg=white,bold] #S"
        set -g status-right "#[fg=green] #(whoami)@#H"
        set -g status-style "bg=default"
        set -g status-justify absolute-centre
        set -g status-left-length 50
        set -g window-status-separator ""
        set -g window-status-format "#[fg=gray]  #I:#W  "
        set -g window-status-current-format "#[fg=cyan,bold]  #I:#W  "

        # New session with current directory and switch
        bind C-s run-shell "tmux new-session -Ad -s \"$(basename #{pane_current_path})\" -c \"#{pane_current_path}\" \; switch-client -t \"$(basename #{pane_current_path})\""

        # Repeatable movement/swapping
        bind -r H swap-pane -U
        bind -r L swap-pane -D
        bind -r J swap-window -t -1
        bind -r K swap-window -t +1
        bind -r p previous-window
        bind -r n next-window
        bind S run-shell -b '${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/save.sh'

        # Pane navigation and resizing
        bind -n M-h select-pane -L
        bind -n M-j select-pane -D
        bind -n M-k select-pane -U
        bind -n M-l select-pane -R
        bind -n M-H resize-pane -L 5
        bind -n M-J resize-pane -D 5
        bind -n M-K resize-pane -U 5
        bind -n M-L resize-pane -R 5

        # Session persistence. Initial restore is performed by systemd.
        set -g @resurrect-dir "~/.local/state/tmux/resurrect"
        set -g @resurrect-capture-pane-contents "off"
        set -g @continuum-save-interval "1"
        set -g @continuum-restore "off"
        run-shell '${pkgs.tmuxPlugins.sensible}/share/tmux-plugins/sensible/sensible.tmux'
        run-shell '${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/resurrect.tmux'
        run-shell '${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/continuum.tmux'
      '';
    };

    zsh = { ... }: {
      initConfig = ''
        _tmux_session_name() {
          local name="''${1:-default}"

          name="''${name//[^[:alnum:]_-]/-}"
          print -r -- "''${name:-default}"
        }

        alias t='tmux'
        alias tl='tmux list-sessions'
        alias tks='tmux kill-server'

        tj() {
          local session="$(_tmux_session_name "$1")"

          if [ -n "$TMUX" ]; then
            if ! tmux has-session -t "=$session" 2>/dev/null; then
              tmux new-session -d -s "$session" -c "$PWD" || return
            fi
            tmux switch-client -t "=$session"
          elif tmux has-session -t "=$session" 2>/dev/null; then
            tmux attach-session -t "=$session"
          else
            tmux new-session -s "$session" -c "$PWD"
          fi
        }

        tjh() {
          tj "$(basename "$PWD")"
        }

        tk() {
          local session

          if [ -z "$1" ]; then
            print -u2 -- 'usage: tk <session>'
            return 2
          fi

          session="$(_tmux_session_name "$1")"
          tmux kill-session -t "=$session"
        }

        _tmux_session_names() {
          tmux list-sessions -F '#S' 2>/dev/null
        }

        _tmux_session_complete() {
          compadd -- $(_tmux_session_names)
        }

        if (( $+functions[compdef] )); then
          compdef _tmux_session_complete tj
          compdef _tmux_session_complete tk
        fi
      '';
    };

    hjem =
      { lib, pkgs, ... }:
      let
        tmuxSessionWrapper = pkgs.writeShellApplication {
          name = "tmux-session-wrapper";
          runtimeInputs = [ pkgs.coreutils pkgs.util-linux ];
          text = ''
            unset TMUX TMUX_TMPDIR

            uid="$(id -u)"
            runtime_dir="/run/user/$uid"
            if [ ! -d "$runtime_dir" ]; then
              runtime_dir="''${XDG_RUNTIME_DIR:-/tmp}"
            fi
            export XDG_RUNTIME_DIR="$runtime_dir"

            lock="$runtime_dir/tmux-sessions.lock"
            exec 9>"$lock"
            if ! flock -n 9; then
              printf 'tmux-session-wrapper: lock is busy: %s\n' "$lock"
              exit 0
            fi

            exec "$@"
          '';
        };
      in
      {
        packages = [
          pkgs.tmux
          pkgs.tmuxPlugins.resurrect
          pkgs.tmuxPlugins.continuum
          tmuxSessionWrapper
        ];

        systemd.services.tmux-sessions-start =
          let
            script = pkgs.writeShellApplication {
              name = "tmux-start-server";
              runtimeInputs = [ pkgs.tmux ];
              text = ''
                tmux_config="$HOME/.config/tmux/tmux.conf"
                printf 'tmux-start-server: starting tmux server\n'
                tmux -f "$tmux_config" start-server
              '';
            };
          in
          {
            description = "Start tmux server";
            wantedBy = [ "default.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${lib.getExe tmuxSessionWrapper} ${lib.getExe script}";
            };
          };

        systemd.services.tmux-sessions-restore =
          let
            script = pkgs.writeShellApplication {
              name = "tmux-restore-sessions";
              runtimeInputs = [ pkgs.tmux ];
              text = ''
                restore_script="${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/restore.sh"

                if tmux has-session 2>/dev/null; then
                  printf 'tmux-restore-sessions: sessions already exist\n'
                  exit 0
                fi

                if [ -x "$restore_script" ]; then
                  printf 'tmux-restore-sessions: restoring saved sessions\n'
                  if "$restore_script"; then
                    printf 'tmux-restore-sessions: restore completed\n'
                  else
                    printf 'tmux-restore-sessions: restore failed\n'
                  fi
                else
                  printf 'tmux-restore-sessions: script unavailable: %s\n' "$restore_script"
                fi
              '';
            };
          in
          {
            description = "Restore saved tmux sessions";
            wantedBy = [ "default.target" ];
            requires = [ "tmux-sessions-start.service" ];
            after = [ "tmux-sessions-start.service" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${lib.getExe tmuxSessionWrapper} ${lib.getExe script}";
            };
          };

        systemd.services.tmux-sessions-default =
          let
            script = pkgs.writeShellApplication {
              name = "tmux-ensure-default";
              runtimeInputs = [ pkgs.tmux ];
              text = ''
                if ! tmux has-session 2>/dev/null; then
                  printf 'tmux-ensure-default: creating fallback session\n'
                  tmux -f "$HOME/.config/tmux/tmux.conf" new-session -Ad -s default
                fi
              '';
            };
          in
          {
            description = "Create the default tmux session when needed";
            wantedBy = [ "default.target" ];
            requires = [ "tmux-sessions-restore.service" ];
            after = [ "tmux-sessions-restore.service" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${lib.getExe tmuxSessionWrapper} ${lib.getExe script}";
            };
          };
      };

    user = {
      linger = true;
    };
  };

  den.schema.user.includes = [
    ({ user }:
      den.batteries.forward {
        each = lib.singleton user;
        fromClass = _: "tmux";
        intoClass = _: "hjem";
        intoPath = _: [ "tmux" ];
        fromAspect = u: u.aspect;
        adaptArgs = args: { inherit (args) pkgs; };
      })
  ];

  den.default.nixos.hjem.extraModules = lib.mkAfter [
    ({ lib, config, pkgs, ... }:
      let
        tmuxConf = pkgs.writeText "tmux.conf" ''
          # Generated by nix-config - do not edit.
          ${config.tmux.initConfig}
        '';
      in
      {
        options.tmux = {
          initConfig = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Tmux configuration emitted before rendered plugins.";
          };
        };

        config = {
          files.".config/tmux/tmux.conf".source = tmuxConf;
        };
      })
  ];
}
