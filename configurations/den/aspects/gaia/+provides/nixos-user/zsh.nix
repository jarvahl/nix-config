{ ... }:
{
  den.aspects.gaia = {
    provides.nixos-user = { ... }: {
      hjem = { lib, sops, ... }: {
        rum.programs.zsh.initConfig = lib.mkBefore ''
          set -a
          if [ -r "${sops.templates.proxy-environment.path}" ]; then
            source "${sops.templates.proxy-environment.path}"
          fi
          if [ -r "${sops.templates.glab-environment.path}" ]; then
            source "${sops.templates.glab-environment.path}"
          fi
          set +a
        '';

        rum.programs.zsh.flake.imports = [
          ({ pkgs, ... }:
            let
              ocCompletion = pkgs.runCommand "oc-zsh-completion" { } ''
                plugin_dir=$out/share/zsh/plugins/oc
                mkdir -p "$plugin_dir"
                ${pkgs.openshift}/bin/oc completion zsh > "$plugin_dir/oc.plugin.zsh"
              '';
            in
            {
              zsh.optPlugins = {
                oc = {
                  package = ocCompletion;
                  source = "share/zsh/plugins/oc/oc.plugin.zsh";
                };
                omz-npm = {
                  package = pkgs.oh-my-zsh;
                  source = "share/oh-my-zsh/plugins/npm/npm.plugin.zsh";
                };
                omz-nvm = {
                  package = pkgs.oh-my-zsh;
                  source = "share/oh-my-zsh/plugins/nvm/nvm.plugin.zsh";
                };
              };
            })
        ];
      };
    };
  };
}
