{ inputs, ... }:

{
  flake-file.inputs.nvf = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:notashelf/nvf";
  };

  den.aspects.nvim.hjem = { pkgs, ... }: {
    programs.nvf = {
      enable = true;
      settings.vim = {
        extraPlugins.fyler = {
          package = pkgs.vimPlugins.fyler-nvim;
          setup = ''
            local fyler = require("fyler")
            -- Fyler's replace mode leaves the code window's dimensions fixed.
            vim.api.nvim_create_autocmd("BufWinEnter", {
              callback = function(event)
                if not vim.api.nvim_buf_get_name(event.buf):match("^fyler%-") then return end
                local win = vim.api.nvim_get_current_win()
                local height, width = vim.wo[win].winfixheight, vim.wo[win].winfixwidth
                vim.api.nvim_create_autocmd("BufWinLeave", {
                  buffer = event.buf,
                  once = true,
                  callback = function()
                    if vim.api.nvim_win_is_valid(win) then
                      vim.wo[win].winfixheight = height
                      vim.wo[win].winfixwidth = width
                    end
                  end,
                })
              end,
            })
            fyler.setup({
              auto_confirm_simple_mutation = true,
              integrations = { icon = "nvim_web_devicons" },
              kind = "replace",
              win_opts = { winbar = "%#Normal# " },
            })
            vim.keymap.set("n", "<leader>e", fyler.open, { desc = "Open Fyler" })
          '';
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
