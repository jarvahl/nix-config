{ den, ... }:
{
  den.aspects.terra.nixos = {
    containers.titan = {
      ephemeral = true;
      bindMounts = {
        "/var/lib/private/n8n" = {
          hostPath = "/var/lib/titan/n8n";
          isReadOnly = false;
        };
        "/var/lib/private/ollama" = {
          hostPath = "/var/lib/titan/ollama";
          isReadOnly = false;
        };
        "/var/lib/private/open-webui" = {
          hostPath = "/var/lib/titan/open-webui";
          isReadOnly = false;
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/titan 0755 root root -"
      "d /var/lib/titan/n8n 0755 root root -"
      "d /var/lib/titan/ollama 0755 root root -"
      "d /var/lib/titan/open-webui 0755 root root -"
    ];
  };

  den.hosts.x86_64-linux.terra = {
    users.jarvahl = { };
    nixosContainers = [ den.hosts.x86_64-linux.titan ];
  };
}
