{ inputs, ... }:

{
  flake-file.inputs.nvf = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:notashelf/nvf";
  };

  den.aspects.nvim.hjem = { lib, pkgs, ... }: {
    programs.nvf = {
      enable = true;
      settings.vim = {
        extraPackages = [ pkgs.ripgrep ];
        extraPlugins.fyler = {
          package = pkgs.fyler-nvim;
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
        keymaps = [
          {
            action = "<cmd>FzfLua files<CR>";
            desc = "Find files";
            key = "<leader>ff";
            mode = "n";
          }
          {
            action = "<cmd>FzfLua live_grep<CR>";
            desc = "Search text";
            key = "<leader>fg";
            mode = "n";
          }
          {
            action = "<cmd>FzfLua buffers<CR>";
            desc = "Find buffers";
            key = "<leader>fb";
            mode = "n";
          }
          {
            action = "<cmd>FzfLua oldfiles<CR>";
            desc = "Find recent files";
            key = "<leader>fr";
            mode = "n";
          }
        ];
        luaConfigRC.ui-theme = ''
          local function apply_ui_theme()
            -- Match the reference screenshot's black UI, not its current Nord palette.
            local backgrounds = {
              CursorLine = "#15161E",
              CursorLineNr = "#000000",
              EndOfBuffer = "#000000",
              FloatBorder = "#000000",
              FloatTitle = "#000000",
              FoldColumn = "#000000",
              FylerFloat = "#000000",
              FylerFloatBorder = "#000000",
              FylerFloatTitle = "#000000",
              FzfLuaBorder = "#000000",
              FzfLuaNormal = "#000000",
              FzfLuaPreviewBorder = "#000000",
              FzfLuaPreviewNormal = "#000000",
              FzfLuaTitle = "#000000",
              LineNr = "#000000",
              Normal = "#000000",
              NormalFloat = "#000000",
              NormalNC = "#000000",
              Pmenu = "#000000",
              PmenuSbar = "#000000",
              PmenuSel = "#292E42",
              SignColumn = "#000000",
              StatusLine = "#000000",
              StatusLineNC = "#000000",
              StatusLineTerm = "#000000",
              StatusLineTermNC = "#000000",
              TabLineFill = "#000000",
              Terminal = "#000000",
              WinBar = "#000000",
              WinBarNC = "#000000",
              WinSeparator = "#000000",
            }
            for group, background in pairs(backgrounds) do
              local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
              highlight.bg = background
              highlight.default = nil -- Otherwise plugin defaults can make this update a no-op.
              vim.api.nvim_set_hl(0, group, highlight)
            end
          end
          vim.api.nvim_create_autocmd("ColorScheme", {
            callback = apply_ui_theme,
            group = vim.api.nvim_create_augroup("black-ui", { clear = true }),
          })
          apply_ui_theme()
        '';
        statusline.lualine = {
          enable = true;
          setupOpts = {
            options = {
              component_separators = "";
              section_separators = "";
              theme = lib.generators.mkLuaInline ''
                (function()
                  local theme = require("lualine.themes.onedark")
                  theme.normal.c.bg = "#000000"
                  theme.inactive.c.bg = "#000000"
                  return theme
                end)()
              '';
            };
            sections = {
              lualine_a = [ "mode" ];
              lualine_b = [ ];
              lualine_c = [
                {
                  "@1" = "filetype";
                  icon_only = true;
                  padding = {
                    left = 1;
                    right = 0;
                  };
                }
                {
                  "@1" = "filename";
                  color = {
                    gui = "bold";
                  };
                  path = 1;
                  symbols = {
                    modified = "•";
                    readonly = "";
                    unnamed = "Empty";
                  };
                }
              ];
              lualine_x = [
                {
                  "@1" = "branch";
                  icon = "";
                }
                "searchcount"
                "%L lines"
                "location"
                {
                  "@1" = "filetype";
                  fmt = lib.generators.mkLuaInline "string.upper";
                  icons_enabled = false;
                }
                "progress"
                {
                  "@1" = "diagnostics";
                  sources = [ "nvim_diagnostic" ];
                  symbols = {
                    error = "▫";
                    hint = "▫";
                    info = "▫";
                    warn = "▫";
                  };
                }
                {
                  "@1" = "diff";
                  symbols = {
                    added = "▪";
                    modified = "▪";
                    removed = "▪";
                  };
                }
              ];
              lualine_y = [ ];
              lualine_z = [ ];
            };
          };
        };
        theme = {
          enable = true;
          name = "onedark";
        };
        vimAlias = true;
        visuals.nvim-web-devicons.enable = true;
      };
    };
  };

  den.default.nixos.hjem.extraModules = [
    inputs.nvf.homeManagerModules.default
  ];
}
