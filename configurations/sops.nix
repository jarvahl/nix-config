{ inputs, self, ... }:
{
  den.default.nixos =
    { config, pkgs, ... }:
    {
      environment.systemPackages = self.lib.withSopsTools pkgs [ ];

      services.pcscd.enable = true;
      environment.variables.SOPS_AGE_KEY_FILE = "/var/lib/sops-nix/key.txt";

      imports = [ inputs.sops-nix.nixosModules.sops ];

      sops.age.keyFile = "/var/lib/sops-nix/key.txt";

      hjem.specialArgs.sops = config.sops;

      systemd.tmpfiles.rules = [
        "d /var/lib/sops-nix 0750 root sops -"
        "z /var/lib/sops-nix/key.txt 0440 root sops -"
      ];

      users.groups.sops = { };
    };

  den.default.user.extraGroups = [ "sops" ];

  flake.lib.withSopsTools = pkgs: packages:
    packages ++ (with pkgs; [
      age
      age-plugin-yubikey
      sops
      yubikey-manager
    ]);

  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
