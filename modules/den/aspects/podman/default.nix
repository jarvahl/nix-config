{ ... }:
{
  den.aspects.podman = {
    nixos = {
      virtualisation = {
        containers.enable = true;
        oci-containers.backend = "podman";

        podman = {
          defaultNetwork.settings.dns_enabled = true;
          dockerCompat = true;
          dockerSocket.enable = true;
          enable = true;
        };
      };
    };

    provides.to-users.user.extraGroups = [ "podman" ];
  };
}
