{ config, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      hjem = lib.evalModules {
        modules = [
          config.flake.hjemModules.default
          ({ lib, ... }: {
            options.packages = lib.mkOption {
              type = lib.types.listOf lib.types.package;
              default = [ ];
            };
            options.files = lib.mkOption {
              type = lib.types.attrs;
              default = { };
            };
            options.systemd.services = lib.mkOption {
              type = lib.types.attrs;
              default = { };
            };

          })
          {
            rum.programs.tmux.flake = {
              enable = true;
              initConfig = lib.mkAfter "set -g @api-test yes";
            };
          }
        ];
        specialArgs = { inherit pkgs; };
      };
      services = hjem.config.systemd.services;
      tmuxConf = hjem.config.files.".config/tmux/tmux.conf".source;
    in
    {
      checks.api = pkgs.runCommand "tmux-flake-api" { } ''
        grep -q '@api-test yes' ${tmuxConf}
        test '${toString (services.tmux-sessions-restore.requires)}' = 'tmux-sessions-start.service'
        test '${toString (services.tmux-sessions-default.requires)}' = 'tmux-sessions-restore.service'
        test '${toString (services.tmux-sessions-restore.after)}' = 'tmux-sessions-start.service'
        test '${toString (services.tmux-sessions-default.after)}' = 'tmux-sessions-restore.service'
        touch "$out"
      '';
    };
}
