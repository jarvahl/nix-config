{ ... }:
{
  den.aspects.apex.nixos = {
    systemd.tmpfiles.rules = [
      "d /var/lib/n8n 0750 1000 1000 -"
    ];

    virtualisation.quadlet = {
      enable = true;

      containers.n8n = {
        autoStart = true;

        containerConfig = {
          image = "docker.n8n.io/n8nio/n8n";
          networks = [ "host" ];
          volumes = [
            "/var/lib/n8n:/home/node/.n8n"
          ];
        };

        serviceConfig.Restart = "always";
      };
    };
  };
}
