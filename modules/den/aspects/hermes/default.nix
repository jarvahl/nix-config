{ ... }:
{
  den.aspects.hermes.nixos = {
    boot.isContainer = true;
    networking.hostName = "hermes";
    sops.defaultSopsFile = ./secrets.yml;
    sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  };
}
