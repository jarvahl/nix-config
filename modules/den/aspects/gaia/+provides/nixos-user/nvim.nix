{ lib
, ...
}:
{
  den.aspects.gaia = {
    provides.nixos-user = {
      nvim = { pkgs, ... }: lib.mkMerge [
        {
          # frontend
          lsp.presets = {
            angular-language-server.enable = true;
            typescript-language-server.enable = true;
          };

          lsp.servers.typescript-language-server.filetypes = [
            "typescript"
            "typescriptreact"
            "javascript"
            "javascriptreact"
          ];

          languages = {
            typescript = {
              enable = true;
              lsp = {
                enable = true;
                servers = [ "typescript-language-server" ];
              };
              treesitter.enable = true;
            };

            html = {
              enable = true;
              lsp.enable = true;
              treesitter.enable = true;
            };

            css = {
              enable = true;
              lsp = {
                enable = true;
              };
              treesitter.enable = true;
            };
          };
        }
        {
          # backend
          lsp.servers.jdt-language-server.cmd = lib.mkForce (lib.generators.mkLuaInline ''
            (function()
              local root = vim.fs.root(0, {
                '.git',
                'build.gradle',
                'build.gradle.kts',
                'build.xml',
                'pom.xml',
                'settings.gradle',
                'settings.gradle.kts',
              }) or vim.fn.getcwd()
              local name = vim.fn.fnamemodify(root, ':t')
              local workspace = name .. '-' .. string.sub(vim.fn.sha256(root), 1, 12)
              return {
                '${lib.getExe pkgs.jdt-language-server}',
                '-configuration',
                vim.fn.stdpath('cache') .. '/jdtls/config',
                '-data',
                vim.fn.stdpath('cache') .. '/jdtls/workspace/' .. workspace,
                unpack(vim.tbl_map(function(arg)
                  return '--jvm-arg=' .. arg
                end, vim.split(os.getenv('JDTLS_JVM_ARGS') or "", '%s+', { trimempty = true }))),
              }
            end)()
          '');

          languages = {
            java = {
              enable = true;
              lsp = {
                enable = true;
              };
              treesitter.enable = true;
            };

            kotlin = {
              enable = true;
              lsp = {
                enable = true;
              };
              treesitter.enable = true;
            };
          };
        }
      ];

      hjem = { pkgs, ... }: {
        environment.sessionVariables.JDTLS_JVM_ARGS = "-javaagent:${pkgs.lombok}/share/java/lombok.jar";
      };
    };
  };
}
