{ inputs, lib, ... }:
{
  den.aspects.tmux = {
    hjem = { pkgs, ... }: {
      rum.programs.tmux.flake = {
        enable = true;
        mode = "vi";
        mouse.enable = true;

        windows = {
          baseIndex = 1;
          paneBaseIndex = 1;
          renumber = true;
        };

        history.limit = 50000;
        prefix2 = "Home";

        extendedKeys = {
          enable = true;
          format = "csi-u";
        };

        persistence.enable = true;

        initConfig = ''
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
          bind C-s run-shell "tmux new-session -Ad -s \"$(basename #{pane_current_path})\" -c \"#{pane_current_path}\" \\; switch-client -t \"$(basename #{pane_current_path})\""

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
        '';
      };

      rum.programs.zsh.initConfig = ''
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
            tmux attach-session -t "$session"
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

    user.linger = true;
  };

  den.default.nixos.hjem.extraModules = lib.mkAfter [
    inputs.tmux.hjemModules.default
  ];
}
