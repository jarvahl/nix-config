{ lib
, ...
}:
{
  den.aspects.vmw71 = {
    provides.nixos-user = { user, ... }: {
      zsh = { pkgs, ... }: {
        integrations = {
          mvn.enable = true;
          npm.enable = true;
        };

        initConfig =
          let
            ocCompletion = pkgs.runCommand "oc-zsh-completion" { } ''
              plugin_dir=$out/share/zsh/plugins/oc
              mkdir -p "$plugin_dir"
              ${pkgs.openshift}/bin/oc completion zsh > "$plugin_dir/oc.plugin.zsh"
            '';
          in
          lib.mkAfter ''
            source "${ocCompletion}/share/zsh/plugins/oc/oc.plugin.zsh"
          '';
      };

      nixos = { config, ... }: {
        hjem.users.${user.userName}.integrations.zsh-nix.initConfig = lib.mkBefore ''
          set -a
          if [ -r "${config.sops.templates.proxy-environment.path}" ]; then
            source "${config.sops.templates.proxy-environment.path}"
          fi
          if [ -r "${config.sops.templates.glab-environment.path}" ]; then
            source "${config.sops.templates.glab-environment.path}"
          fi
          set +a
        '';
      };
    };
  };
}
