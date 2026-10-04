{ inputs, moduleWithSystem, ... }:

{
  flake.nixosModules.nvim = moduleWithSystem ({ self', ... }: {
    programs.neovim = {
      enable = true;
      package = self'.packages.nvim;
    };
  });

  perSystem = { pkgs, ... }: {
    packages.nvim = (inputs.nvf.lib.neovimConfiguration {
      modules = [ ];
      inherit pkgs;
    }).neovim;
  };
}
