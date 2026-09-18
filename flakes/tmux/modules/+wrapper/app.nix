{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      tmux = self.lib.tmuxConfiguration { inherit pkgs; };
    in
    {
      apps.default = {
        type = "app";
        program = "${tmux}/bin/tmux";
        meta.description = "Run the tmux-flake configuration";
      };
    };
}
