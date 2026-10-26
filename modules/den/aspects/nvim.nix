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
        filetree.nvimTree = {
          enable = true;
          mappings.toggle = "<leader>e";
        };
        fzf-lua.enable = true;
        theme.enable = true;
        vimAlias = true;
        visuals.nvim-web-devicons.enable = true;
      };
    };
  };

  den.default.nixos.hjem.extraModules = [
    inputs.nvf.homeManagerModules.default
  ];
}
