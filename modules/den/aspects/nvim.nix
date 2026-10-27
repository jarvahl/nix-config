{ inputs, lib, ... }:

{
  flake-file.inputs.nvf = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:notashelf/nvf";
  };

  den.aspects.nvim.hjem = {
    programs.nvf = {
      enable = true;
      settings.vim = {
        autocmds = [
          {
            callback = lib.generators.mkLuaInline ''
              function(args)
                -- Apply after nvim-tree finishes configuring its window.
                vim.schedule(function()
                  for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
                    vim.wo[win].winbar = "%#NvimTreeNormal# "
                  end
                end)
              end
            '';
            desc = "Non-selectable top padding for the file tree";
            event = [ "BufWinEnter" ];
            pattern = [ "NvimTree_*" ];
          }
        ];
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
