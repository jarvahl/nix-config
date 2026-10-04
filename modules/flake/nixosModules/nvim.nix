{ inputs, moduleWithSystem, ... }:

{
  flake.nixosModules.nvim = moduleWithSystem ({ self', ... }: {
    programs.neovim = {
      enable = true;
      package = self'.packages.nvim;
    };
  });

  perSystem = { lib, pkgs, ... }: {
    packages.nvim = (inputs.nvf.lib.neovimConfiguration {
      modules = [ ];
      inherit pkgs;
    }).neovim.overrideAttrs (old: {
      meta = old.meta // {
        license = lib.licenses.asl20;
        platforms = lib.platforms.all;
      };
    });
  };
}
