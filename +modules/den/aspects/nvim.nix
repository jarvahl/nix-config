{ inputs, ... }:

{
  flake-file.inputs.nvf = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:notashelf/nvf";
  };

  den.aspects.nvim.hjem = {
    programs.nvf = {
      enable = true;
      settings.vim = {
        theme.enable = true;
        vimAlias = true;
      };
    };
  };

  den.default.nixos.hjem.extraModules = [
    inputs.nvf.homeManagerModules.default
  ];
}
