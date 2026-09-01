{ inputs, ... }:
{
  den.default.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.sops ];
      environment.variables.SOPS_AGE_KEY_FILE = "/var/lib/sops-nix/key.txt";

      imports = [ inputs.sops-nix.nixosModules.sops ];

      sops.age.keyFile = "/var/lib/sops-nix/key.txt";

      systemd.tmpfiles.rules = [
        "d /var/lib/sops-nix 0750 root sops -"
        "z /var/lib/sops-nix/key.txt 0440 root sops -"
      ];

      users.groups.sops = { };
    };

  den.default.user.extraGroups = [ "sops" ];

  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
