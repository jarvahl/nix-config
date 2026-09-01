{ den, lib, ... }:
{
  den.aspects.clipboard = {
    nvim = {
      luaConfigPost = ''
        vim.g.clipboard = {
          name = 'pbcopy/pbpaste',
          copy = {
            ['+'] = { 'pbcopy' },
            ['*'] = { 'pbcopy' },
          },
          paste = {
            ['+'] = { 'pbpaste' },
            ['*'] = { 'pbpaste' },
          },
          cache_enabled = 0,
        }
        vim.opt.clipboard = 'unnamedplus'
      '';
    };

    tmux = {
      initConfig = lib.mkAfter ''
        set -g set-clipboard on
        bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
        bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "pbcopy"
        bind-key -T copy-mode Enter send-keys -X copy-pipe-and-cancel "pbcopy"
        bind-key -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"
      '';
    };

    nixos =
      { config, pkgs, ... }:
      let
        isWsl = config.wsl.enable or false;
        backend = if isWsl then "wsl" else "wayland";

        pbcopy-wsl = pkgs.writeShellApplication {
          name = "pbcopy-wsl";
          text = ''
            if command -v clip.exe >/dev/null 2>&1; then
              exec clip.exe "$@"
            fi

            exec /mnt/c/Windows/System32/clip.exe "$@"
          '';
        };

        pbpaste-wsl = pkgs.writeShellApplication {
          name = "pbpaste-wsl";
          runtimeInputs = [ pkgs.gnused ];
          text = ''
            powershell=powershell.exe
            if ! command -v "$powershell" >/dev/null 2>&1; then
              powershell=/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe
            fi

            set +e
            "$powershell" \
              -NoProfile \
              -NonInteractive \
              -Command '[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new(); Get-Clipboard -Raw' \
              | sed 's/\r$//'
            status="''${PIPESTATUS[0]}"
            set -e
            exit "$status"
          '';
        };

        pbcopy-wayland = pkgs.writeShellApplication {
          name = "pbcopy-wayland";
          runtimeInputs = [ pkgs.wl-clipboard ];
          text = ''
            exec wl-copy "$@"
          '';
        };

        pbpaste-wayland = pkgs.writeShellApplication {
          name = "pbpaste-wayland";
          runtimeInputs = [ pkgs.wl-clipboard ];
          text = ''
            exec wl-paste --no-newline "$@"
          '';
        };

        pbcopyBackend = if isWsl then pbcopy-wsl else pbcopy-wayland;
        pbpasteBackend = if isWsl then pbpaste-wsl else pbpaste-wayland;

        pbcopy = pkgs.writeShellApplication {
          name = "pbcopy";
          runtimeInputs = [ pbcopyBackend ];
          text = ''
            exec pbcopy-${backend} "$@"
          '';
        };

        pbpaste = pkgs.writeShellApplication {
          name = "pbpaste";
          runtimeInputs = [ pbpasteBackend ];
          text = ''
            exec pbpaste-${backend} "$@"
          '';
        };
      in
      {
        environment.systemPackages = [
          pbcopy
          pbpaste
          pbcopyBackend
          pbpasteBackend
        ] ++ lib.optionals (!isWsl) [
          pkgs.wl-clipboard
        ];
      };
  };

  den.policies.clipboard-user =
    { ... }:
    [ (den.lib.policy.include den.aspects.clipboard) ];

  den.schema.user.includes = [ den.policies.clipboard-user ];
}
