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
              function()
                -- Apply after nvim-tree finishes configuring its window.
                vim.schedule(function()
                  for _, win in ipairs(vim.api.nvim_list_wins()) do
                    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "NvimTree" then
                      vim.wo[win].winbar = "%#NvimTreeNormal# "
                    end
                  end
                end)
              end
            '';
            desc = "Non-selectable top padding for the file tree";
            event = [
              "BufWinEnter"
              "VimEnter"
            ];
            pattern = [ "*" ];
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
