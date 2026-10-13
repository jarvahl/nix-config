{ inputs, ... }:

{
  den.aspects.nvim.homeManager = {
    imports = [ inputs.nvf.homeManagerModules.default ];

    programs.nvf = {
      enable = true;
      settings.vim = {
        theme.enable = true;
        vimAlias = true;
      };
    };
  };

  flake-file.inputs.nvf = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:notashelf/nvf";
  };
}
