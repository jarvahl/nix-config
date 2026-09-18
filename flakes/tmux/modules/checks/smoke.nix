{ config, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      tmuxConfig = config.flake.lib.tmuxConfigText {
        inherit pkgs;
        modules = [
          {
            initConfig = lib.mkAfter ''
              set -g @tmux-flake-smoke "ok"
            '';
          }
        ];
      };
    in
    {
      checks.smoke = pkgs.runCommand "tmux-flake-smoke" { } ''
        config=${pkgs.writeText "tmux.conf" tmuxConfig}
        grep -q 'set -g @resurrect-dir' "$config"
        grep -q 'set -g @tmux-flake-smoke "ok"' "$config"
        grep -q 'resurrect/resurrect.tmux' "$config"
        grep -q 'continuum/continuum.tmux' "$config"
        test "$(grep -n 'set -g @resurrect-dir' "$config" | cut -d: -f1)" -lt "$(grep -n '@tmux-flake-smoke' "$config" | cut -d: -f1)"
        touch "$out"
      '';
    };
}
