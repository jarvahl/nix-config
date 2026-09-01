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
        bind | split-window -h
        bind - split-window -v
        unbind '"'
        unbind %

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

        # Pane picker labels
        bind q {
          set -w pane-border-status top
          set -w pane-border-format "#{?pane_active,#[fg=colour220] #{pane_index} #{pane_current_command} ,#[fg=colour75] #{pane_index} #[fg=colour245]#{pane_current_command} }"
          switch-client -T pane-picker
          run-shell -b "sleep 7; tmux set -w pane-border-status off"
        }
        bind -T pane-picker 0 select-pane -t :.0 \; set -w pane-border-status off
        bind -T pane-picker 1 select-pane -t :.1 \; set -w pane-border-status off
        bind -T pane-picker 2 select-pane -t :.2 \; set -w pane-border-status off
        bind -T pane-picker 3 select-pane -t :.3 \; set -w pane-border-status off
        bind -T pane-picker 4 select-pane -t :.4 \; set -w pane-border-status off
        bind -T pane-picker 5 select-pane -t :.5 \; set -w pane-border-status off
        bind -T pane-picker 6 select-pane -t :.6 \; set -w pane-border-status off
        bind -T pane-picker 7 select-pane -t :.7 \; set -w pane-border-status off
        bind -T pane-picker 8 select-pane -t :.8 \; set -w pane-border-status off
        bind -T pane-picker 9 select-pane -t :.9 \; set -w pane-border-status off
        bind -T pane-picker Escape set -w pane-border-status off
        bind -T pane-picker q set -w pane-border-status off

        # Open new panes/windows in current directory
        bind c new-window -c "#{pane_current_path}"
        bind '"' split-window -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"

        # New session with current directory name and switch
        bind C-s run-shell "tmux new-session -d -s \"$(basename #{pane_current_path})\" -c \"#{pane_current_path}\" \; switch-client -t \"$(basename #{pane_current_path})\""

        # Repeatable movement/swapping (using prefix)
        # Swap panes
        bind -r H swap-pane -U
        bind -r L swap-pane -D
        # Swap windows
        bind -r J swap-window -t -1
        bind -r K swap-window -t +1

        # Pane navigation and resizing
        bind -n M-h select-pane -L
        bind -n M-j select-pane -D
        bind -n M-k select-pane -U
        bind -n M-l select-pane -R

        bind -n M-H resize-pane -L 5
        bind -n M-J resize-pane -D 5
        bind -n M-K resize-pane -U 5
        bind -n M-L resize-pane -R 5

        # Repeatable navigation
        # Navigate windows
        bind -r p previous-window
        bind -r n next-window

        # Session persistence
        bind S run-shell -b 'if systemctl --user start tmux-sessions-save.service; then tmux display-message "tmux sessions saved"; else tmux display-message "tmux sessions save failed"; fi'

        # Plugins
        run-shell '${pkgs.tmuxPlugins.sensible}/share/tmux-plugins/sensible/sensible.tmux'
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
            tmux has-session -t "=$session" 2>/dev/null ||
              tmux new-session -d -s "$session" -c "$PWD"
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
        sessionRuntimeInputs = [
          pkgs.coreutils
          pkgs.findutils
          pkgs.gnugrep
          pkgs.gnused
          pkgs.tmux
          pkgs.util-linux
        ];

        tmuxEnsureSessions = pkgs.writeShellApplication {
          name = "tmux-ensure-sessions";
          runtimeInputs = sessionRuntimeInputs;
          text = ''
            unset TMUX TMUX_TMPDIR

            uid="$(id -u)"
            runtime_dir="/run/user/$uid"
            if [ ! -d "$runtime_dir" ]; then
              runtime_dir="''${XDG_RUNTIME_DIR:-/tmp}"
            fi
            export XDG_RUNTIME_DIR="$runtime_dir"

            tmux_config="$HOME/.config/tmux/tmux.conf"
            state_home="''${XDG_STATE_HOME:-$HOME/.local/state}"
            state_dir="$state_home/tmux"
            snapshot_dir="$state_dir/snapshot"
            fallback_shell="${pkgs.runtimeShell}"
            lock="$runtime_dir/tmux-sessions.lock"

            log() {
              printf 'tmux-ensure-sessions: %s\n' "$*"
            }

            log_state() {
              log "env uid=$uid HOME=$HOME XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-unset} TMUX_TMPDIR=''${TMUX_TMPDIR:-unset}"

              if socket="$(tmux display-message -p '#{socket_path}' 2>/dev/null)"; then
                log "socket=$socket"
              fi

              if sessions="$(tmux list-sessions -F '#S:#{session_windows}:#{session_attached}' 2>&1)"; then
                printf '%s\n' "$sessions" | while IFS= read -r session; do
                  log "session=$session"
                done
              else
                log "list-sessions failed: $sessions"
              fi
            }

            has_window() {
              tmux list-windows -t "$1" -F '#{window_index}' 2>/dev/null | grep -qx "$2"
            }

            has_pane() {
              tmux list-panes -t "$1:$2" -F '#{pane_index}' 2>/dev/null | grep -qx "$3"
            }

            read_file() {
              if [ -f "$1" ]; then
                IFS= read -r value < "$1"
                printf '%s' "$value"
              fi
            }

            restore_shell() {
              if [ -n "''${SHELL:-}" ] && [ -x "$SHELL" ]; then
                printf '%s' "$SHELL"
                return
              fi

              while IFS=: read -r _name _password passwd_uid _gid _gecos _home passwd_shell; do
                if [ "$passwd_uid" = "$uid" ] && [ -x "$passwd_shell" ]; then
                  printf '%s' "$passwd_shell"
                  return
                fi
              done < /etc/passwd

              printf '%s' "$fallback_shell"
            }

            restore_contents_command() {
              contents_file="$1"

              printf 'sed'
              printf ' -e %q' '/^---------------------------$/d'
              printf ' -e %q' '/restored history/d'
              printf ' -e %q' '/restored scrollback/d'
              printf ' -e %q' '/tmux-ensure/d'
              printf ' -e %q' '/ensure-sessions/d'
              printf ' -e %q' '/tmux-save/d'
              printf ' -e %q' '/save-sessions/d'
              printf ' %q' "$contents_file"
            }

            restore_separator_command() {
              cat <<'RESTORE_SEPARATOR'
            cols="$(${pkgs.ncurses}/bin/tput cols 2>/dev/null || printf 80)"
            case "$cols" in
              *[!0-9]* | "") cols=80 ;;
            esac

            label=" restored scrollback "
            label_len="''${#label}"
            draw_rule() {
              count="$1"
              while [ "$count" -gt 0 ]; do
                printf '─'
                count=$((count - 1))
              done
            }

            if [ "$cols" -le "$label_len" ]; then
              printf '\n%s\n\n' "$label"
            else
              fill=$((cols - label_len))
              left=$((fill / 2))
              right=$((fill - left))

              printf '\n'
              draw_rule "$left"
              printf '%s' "$label"
              draw_rule "$right"
              printf '\n\n'
            fi
            RESTORE_SEPARATOR
            }

            pane_restore_command() {
              contents_file="$1/contents"
              if [ -s "$contents_file" ]; then
                shell="$(restore_shell)"
                contents_command="$(restore_contents_command "$contents_file")"
                separator_command="$(restore_separator_command)"
                log "restoring pane contents file=$contents_file shell=$shell"
                printf '%s; %s; exec %q -l' "$contents_command" "$separator_command" "$shell"
              fi
            }

            first_pane_index() {
              panes_dir="$1"
              first_pane="$(find "$panes_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort -V | head -n 1 || true)"
              if [ -z "$first_pane" ]; then
                printf '1'
                return
              fi
              printf '%s' "$first_pane"
            }

            restore_window() {
              session_name="$1"
              window_index="$2"
              window_dir="$3"
              window_name="$(read_file "$window_dir/name")"
              dir="$(read_file "$window_dir/dir")"
              layout="$(read_file "$window_dir/layout")"
              panes_dir="$window_dir/panes"
              first_pane="$(first_pane_index "$panes_dir")"
              first_pane_dir="$panes_dir/$first_pane"

              if [ -z "$window_name" ]; then
                window_name="zsh"
              fi

              if [ -f "$first_pane_dir/dir" ]; then
                dir="$(read_file "$first_pane_dir/dir")"
              fi

              if [ -z "$dir" ] || [ ! -d "$dir" ]; then
                log "using home for session=$session_name window=$window_index because dir is missing"
                dir="$HOME"
              fi

              log "restoring session=$session_name window=$window_index name=$window_name dir=$dir"
              restore_command="$(pane_restore_command "$first_pane_dir")"
              if ! tmux has-session -t "$session_name" 2>/dev/null; then
                if [ -n "$restore_command" ]; then
                  tmux -f "$tmux_config" new-session -d -s "$session_name" -n "$window_name" -c "$dir" "$restore_command"
                else
                  tmux -f "$tmux_config" new-session -d -s "$session_name" -n "$window_name" -c "$dir"
                fi

                current_index="$(tmux display-message -p -t "$session_name:" '#{window_index}' 2>/dev/null || true)"
                if [ -n "$current_index" ] && [ "$current_index" != "$window_index" ]; then
                  tmux move-window -s "$session_name:$current_index" -t "$session_name:$window_index" 2>/dev/null || true
                fi
              elif ! has_window "$session_name" "$window_index"; then
                if [ -n "$restore_command" ]; then
                  tmux new-window -d -t "$session_name:$window_index" -n "$window_name" -c "$dir" "$restore_command"
                else
                  tmux new-window -d -t "$session_name:$window_index" -n "$window_name" -c "$dir"
                fi
              else
                tmux rename-window -t "$session_name:$window_index" "$window_name" 2>/dev/null || true
              fi

              while IFS= read -r pane_index; do
                if [ "$pane_index" = "$first_pane" ] || has_pane "$session_name" "$window_index" "$pane_index"; then
                  continue
                fi

                pane_dir="$panes_dir/$pane_index"
                pane_cwd="$(read_file "$pane_dir/dir")"

                if [ -z "$pane_cwd" ] || [ ! -d "$pane_cwd" ]; then
                  pane_cwd="$HOME"
                fi

                log "restoring pane session=$session_name window=$window_index pane=$pane_index dir=$pane_cwd"
                restore_command="$(pane_restore_command "$pane_dir")"
                if [ -n "$restore_command" ]; then
                  tmux split-window -d -t "$session_name:$window_index" -c "$pane_cwd" "$restore_command"
                else
                  tmux split-window -d -t "$session_name:$window_index" -c "$pane_cwd"
                fi
              done < <(find "$panes_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort -V)

              if [ -n "$layout" ]; then
                tmux select-layout -t "$session_name:$window_index" "$layout" 2>/dev/null || true
              fi
            }

            restore_snapshot() {
              restored=0

              for session_dir in "$snapshot_dir"/sessions/*; do
                [ -d "$session_dir" ] || continue
                session_name="$(read_file "$session_dir/name")"
                [ -n "$session_name" ] || continue

                while IFS= read -r window_index; do
                  window_dir="$session_dir/windows/$window_index"
                  [ -d "$window_dir" ] || continue
                  restore_window "$session_name" "$window_index" "$window_dir"
                  restored=1
                done < <(find "$session_dir/windows" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort -V)
              done

              [ "$restored" -eq 1 ]
            }

            mkdir -p "$state_dir"

            exec 9>"$lock"
            if ! flock -n 9; then
              log "lock is busy: $lock"
              exit 0
            fi

            if tmux has-session 2>/dev/null; then
              log "server already has sessions"
              log_state
              exit 0
            fi

            exec 9>&-

            if [ -d "$snapshot_dir/sessions" ]; then
              log "restoring snapshot: $snapshot_dir"
              restore_snapshot || true
            else
              log "no snapshot found: $snapshot_dir"
            fi

            if ! tmux has-session 2>/dev/null; then
              log "creating fallback default session"
              tmux -f "$tmux_config" new-session -Ad -s default
            fi

            log "state after ensure"
            log_state
          '';
        };

        tmuxSaveSessions = pkgs.writeShellApplication {
          name = "tmux-save-sessions";
          runtimeInputs = sessionRuntimeInputs;
          text = ''
            unset TMUX TMUX_TMPDIR

            uid="$(id -u)"
            runtime_dir="/run/user/$uid"
            if [ ! -d "$runtime_dir" ]; then
              runtime_dir="''${XDG_RUNTIME_DIR:-/tmp}"
            fi
            export XDG_RUNTIME_DIR="$runtime_dir"

            state_home="''${XDG_STATE_HOME:-$HOME/.local/state}"
            state_dir="$state_home/tmux"
            snapshot_dir="$state_dir/snapshot"
            snapshot_tmp="$state_dir/snapshot.tmp"
            snapshot_old="$state_dir/snapshot.old"
            lock="$runtime_dir/tmux-sessions.lock"

            log() {
              printf 'tmux-save-sessions: %s\n' "$*"
            }

            log_state() {
              log "env uid=$uid HOME=$HOME XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-unset} TMUX_TMPDIR=''${TMUX_TMPDIR:-unset}"

              if socket="$(tmux display-message -p '#{socket_path}' 2>/dev/null)"; then
                log "socket=$socket"
              fi

              if sessions="$(tmux list-sessions -F '#S:#{session_windows}:#{session_attached}' 2>&1)"; then
                printf '%s\n' "$sessions" | while IFS= read -r session; do
                  log "session=$session"
                done
              else
                log "list-sessions failed: $sessions"
              fi
            }

            snapshot_key() {
              printf '%s' "$1" | sha256sum | cut -d ' ' -f 1
            }

            trim_trailing_empty_lines() {
              sed -e :a -e '/^[[:space:]]*$/{$d;N;ba' -e '}'
            }

            sanitize_pane_contents() {
              sed \
                -e '/^---------------------------$/d' \
                -e '/restored history/d' \
                -e '/restored scrollback/d' \
                -e '/tmux-ensure/d' \
                -e '/ensure-sessions/d' \
                -e '/tmux-save/d' \
                -e '/save-sessions/d'
            }

            if ! tmux has-session 2>/dev/null; then
              log "no server running, skipping save"
              log_state
              exit 0
            fi

            exec 9>"$lock"
            if ! flock -n 9; then
              log "lock is busy: $lock"
              exit 0
            fi

            if ! tmux has-session 2>/dev/null; then
              log "server disappeared before save"
              log_state
              exit 0
            fi

            rm -rf "$snapshot_tmp"
            mkdir -p "$snapshot_tmp/sessions"

            tmux list-windows -a -F "#S	#I	#W	#{pane_current_path}	#{window_layout}" |
              while IFS="$(printf '\t')" read -r session_name window_index window_name window_dir window_layout; do
                session_dir="$snapshot_tmp/sessions/$(snapshot_key "$session_name")"
                window_dir_path="$session_dir/windows/$window_index"

                mkdir -p "$window_dir_path/panes"
                printf '%s\n' "$session_name" > "$session_dir/name"
                printf '%s\n' "$window_name" > "$window_dir_path/name"
                printf '%s\n' "$window_dir" > "$window_dir_path/dir"
                printf '%s\n' "$window_layout" > "$window_dir_path/layout"
              done

            tmux list-panes -a -F "#S	#I	#P	#{pane_current_path}	#{pane_id}" |
              while IFS="$(printf '\t')" read -r session_name window_index pane_index pane_dir pane_id; do
                session_dir="$snapshot_tmp/sessions/$(snapshot_key "$session_name")"
                pane_dir_path="$session_dir/windows/$window_index/panes/$pane_index"

                mkdir -p "$pane_dir_path"
                printf '%s\n' "$pane_dir" > "$pane_dir_path/dir"
                tmux capture-pane -epJ -S - -t "$pane_id" |
                  sanitize_pane_contents |
                  trim_trailing_empty_lines > "$pane_dir_path/contents" || true
              done

            rm -rf "$snapshot_old"
            if [ -d "$snapshot_dir" ]; then
              mv "$snapshot_dir" "$snapshot_old"
            fi
            mv "$snapshot_tmp" "$snapshot_dir"
            rm -rf "$snapshot_old"

            log "saved snapshot: $snapshot_dir"
            log_state
          '';
        };
      in
      {
        packages = [
          pkgs.tmux
          tmuxEnsureSessions
          tmuxSaveSessions
        ];
        systemd.services.tmux-sessions-ensure = {
          description = "Ensure tmux sessions";
          wantedBy = [ "default.target" ];
          serviceConfig = {
            Type = "oneshot";
            KillMode = "process";
            ExecStart = lib.getExe tmuxEnsureSessions;
          };
        };
        systemd.timers.tmux-sessions-ensure = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "5s";
            OnUnitActiveSec = "30s";
            Unit = "tmux-sessions-ensure.service";
          };
        };
        systemd.services.tmux-sessions-save = {
          description = "Save tmux sessions";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = lib.getExe tmuxSaveSessions;
          };
        };
        systemd.timers.tmux-sessions-save = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "1min";
            OnUnitActiveSec = "1min";
            Unit = "tmux-sessions-save.service";
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
