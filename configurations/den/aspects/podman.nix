{ ... }:
{
  den.aspects.podman = {
    hjem = { ... }: {
      rum.programs.zsh.flake.imports = [
        ({ pkgs, ... }:
          let
            dockerPlugin = pkgs.runCommand "oh-my-zsh-docker-plugin" { } ''
              plugin_dir=$out/share/oh-my-zsh/plugins/docker
              mkdir -p "$plugin_dir"
              cp -R ${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/docker/. "$plugin_dir/"
              chmod -R u+w "$plugin_dir"
              sed -i '/^# If the completion file/,$d' "$plugin_dir/docker.plugin.zsh"
            '';
          in
          {
            zsh.optPlugins = {
              omz-docker = {
                package = dockerPlugin;
                source = "share/oh-my-zsh/plugins/docker/docker.plugin.zsh";
                init = ''
                  fpath=("${dockerPlugin}/share/oh-my-zsh/plugins/docker/completions" $fpath)
                '';
              };
              omz-docker-compose = {
                package = pkgs.oh-my-zsh;
                source = "share/oh-my-zsh/plugins/docker-compose/docker-compose.plugin.zsh";
              };
            };
          })
      ];
    };

    nixos =
      { pkgs, ... }:
      {
        virtualisation = {
          containers = {
            enable = true;

            containersConf.settings = {
              engine = {
                compose_warning_logs = false;
              };
            };
          };

          podman = {
            enable = true;
            dockerCompat = true;
            defaultNetwork.settings.dns_enabled = true;
            autoPrune.enable = true;
          };

          oci-containers.backend = "podman";
        };

        environment.systemPackages = with pkgs; [
          docker-compose
          fuse-overlayfs
        ];

        environment.variables = {
          PODMAN_IGNORE_CGROUPSV1_WARNING = "1";
          DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
        };
      };
  };
}
