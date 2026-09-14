{ ... }:
{
  den.aspects.podman = {
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
