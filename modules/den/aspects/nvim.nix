{ den, lib, inputs, ... }:
{
  den.aspects.nvim = {
    nvim = { pkgs, ... }:
      lib.mkMerge [
        {
          # ui
          theme.enable = true;
          statusline.lualine.enable = true;
          visuals.nvim-web-devicons.enable = true;
          mini.icons.enable = true;

          diagnostics = {
            enable = true;
            config.signs.text = lib.generators.mkLuaInline ''
              {
                [vim.diagnostic.severity.ERROR] = "󰅚 ",
                [vim.diagnostic.severity.WARN] = "󰀪 ",
                [vim.diagnostic.severity.INFO] = "󰋽 ",
                [vim.diagnostic.severity.HINT] = "󰌶 ",
              }
            '';
          };

          luaConfigPost = ''
            vim.o.mouse = "a"
          '';
        }
        {
          # completion
          autocomplete.blink-cmp = {
            enable = true;
            setupOpts = {
              sources = {
                default = lib.mkBefore [ "filemention" ];
                providers.filemention = {
                  name = "filemention";
                  module = "filemention.sources.blink";
                  enabled = true;
                  should_show_items = lib.generators.mkLuaInline ''
                    function(_, items)
                      return require("filemention").enabled(0) and #items > 0
                    end
                  '';
                };
              };
              keymap = {
                "<Down>" = [ "select_next" "fallback" ];
                "<Up>" = [ "select_prev" "fallback" ];
              };
              cmdline.keymap = {
                "<Down>" = [ "select_next" "show" "fallback" ];
                "<Up>" = [ "select_prev" "fallback" ];
              };
            };
          };
        }
        {
          # lsp
          lsp = {
            enable = true;
            formatOnSave = false;
            lspconfig.enable = true;
            mappings.format = null;
          };
          languages.nix = {
            enable = true;
            format.enable = true;
            lsp.enable = true;
          };
          languages.markdown = {
            enable = true;
            extensions.render-markdown-nvim.enable = true;
            format = {
              enable = true;
              type = [ "mdformat" ];
            };
          };
          session.nvim-session-manager = {
            enable = true;
            setupOpts = {
              autoload_mode = "CurrentDir";
              autosave_last_session = true;
              autosave_only_in_session = false;
            };
          };
        }
        {
          # fzf-lua
          fzf-lua = {
            enable = true;
            setupOpts = {
              winopts = {
                width = 1.0;
                height = 1.0;
                row = 0.50;
                col = 0.50;
              };
              keymap = {
                fzf = {
                  "ctrl-y" = "transform-query(pbpaste)";
                  "alt-v" = "transform-query(pbpaste)";
                };
              };
            };
          };
          keymaps = [
            {
              key = "<leader>ff";
              mode = "n";
              action = "<cmd>FzfLua files<CR>";
              desc = "Find files";
            }
            {
              key = "<leader>fg";
              mode = "n";
              action = "<cmd>FzfLua live_grep<CR>";
              desc = "Search in files";
            }
            {
              key = "<leader>fk";
              mode = "n";
              action = "<cmd>FzfLua keymaps<CR>";
              desc = "Find keymaps";
            }
            {
              key = "<leader>fb";
              mode = "n";
              action = "<cmd>FzfLua buffers<CR>";
              desc = "Find buffers";
            }
            {
              key = "<C-.>";
              mode = "n";
              action = "<cmd>FzfLua lsp_code_actions<CR>";
              desc = "Code actions";
            }
          ];
        }
        {
          # VS Code-style editor keymaps
          keymaps = [
            {
              key = "<leader>bd";
              mode = "n";
              action = "<cmd>lua require('bufdelete').bufdelete(0, false)<CR>";
              desc = "Close buffer";
            }
            {
              key = "<F2>";
              mode = "n";
              action = "<cmd>lua vim.lsp.buf.rename()<CR>";
              desc = "Rename symbol";
            }
            {
              key = "<F12>";
              mode = "n";
              action = "<cmd>lua vim.lsp.buf.definition()<CR>";
              desc = "Go to definition";
            }
            {
              key = "<S-F12>";
              mode = "n";
              action = "<cmd>lua vim.lsp.buf.references()<CR>";
              desc = "Find references";
            }
            # FIXME: nvf maps lsp.mappings.format to vim.lsp.buf.format, but
            # language formatters such as markdown/mdformat are registered via conform.
            {
              key = "<leader>lf";
              mode = "n";
              action = "<cmd>lua require('conform').format({ lsp_format = 'fallback' })<CR>";
              desc = "Format";
            }
          ];
        }
        {
          # buffer cleanup
          extraPlugins.nvim-early-retirement.package = pkgs.vimPlugins.nvim-early-retirement;

          luaConfigPost = ''
            require("early-retirement").setup({
              retirementAgeMins = 30,
              minimumBufferNum = 5,
              ignoreAltFile = true,
              ignoreUnsavedChangesBufs = true,
              ignoreSpecialBuftypes = true,
              ignoreVisibleBufs = true,
              notificationOnAutoClose = false,
            })
          '';
        }
        {
          # file mentions
          extraPlugins.filemention.package = pkgs.vimUtils.buildVimPlugin {
            pname = "filemention.nvim";
            version = "unstable";
            src = pkgs.fetchFromGitHub {
              owner = "not-manu";
              repo = "filemention.nvim";
              rev = "d8aa9116fa441d0529c53bb5cb2c321f30d9544d";
              hash = "sha256-XeLy1GlSSD3xg5KZWQKJH+riTdcN8e2iIpF7dbGl2MY=";
            };
          };

          luaConfigPost = ''
            require('filemention').setup({
              root = "cwd",
            })
          '';
        }
        {
          # indentation detection
          extraPlugins.guess-indent.package = pkgs.vimPlugins.guess-indent-nvim;

          luaConfigPost = ''
            require('guess-indent').setup({})
          '';
        }
        {
          # fyler
          extraPlugins.fyler.package = pkgs.vimPlugins.fyler-nvim;

          luaConfigPost = ''
            vim.api.nvim_create_user_command("FylerBuffers", function()
              local fyler = require("fyler")

              fyler.toggle({ root_path = vim.uv.cwd() })
            end, {})

            require('fyler').setup({
              follow_current_file = true,
              kind = "floating",
              kind_presets = {
                floating = {
                  width = "100%",
                  height = "100%",
                  row = "start",
                  col = "start",
                },
              },
            })
          '';

          keymaps = [
            {
              key = "<C-b>";
              mode = "n";
              action = "<cmd>FylerBuffers<CR>";
              desc = "Toggle file explorer";
            }
            {
              key = "<leader>e";
              mode = "n";
              action = "<cmd>FylerBuffers<CR>";
              desc = "Toggle file explorer";
            }
          ];
        }
      ];

    hjem = {
      environment.sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
        GIT_EDITOR = "nvim";
      };
    };

    nixos = {
      environment.sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
        GIT_EDITOR = "nvim";
      };
    };
  };

  den.schema.user.includes = [
    ({ user, ... }:
      den.batteries.forward {
        each = lib.singleton user;
        fromClass = _: "nvim";
        intoClass = _: "hjem";
        intoPath = _: [ "nvf" "vim" ];
        fromAspect = u: u.aspect;
        adaptArgs = args: { inherit (args) pkgs; };
      })
  ];

  den.default.nixos.hjem.extraModules = lib.mkAfter [
    ({ inputs, lib, config, pkgs, ... }:
      let
        nvfInput = inputs.nvf or (throw "inputs.nvf is required in flake inputs.");
      in
      {
        options.nvf = lib.mkOption {
          type = lib.types.deferredModule;
          default = { };
        };

        config = {
          packages = [
            (nvfInput.lib.neovimConfiguration {
              inherit pkgs;
              modules = [ config.nvf ];
            }).neovim
          ];
        };
      })
    {
      _module.args.inputs = { inherit (inputs) nvf; };
    }
  ];

  flake-file.inputs.nvf.url = "github:notashelf/nvf";
}
