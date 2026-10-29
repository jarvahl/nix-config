{ lib, ... }:
let
  homePath =
    home: path:
    if lib.hasPrefix "/" (toString path) then
      path
    else
      "${home}/${lib.removePrefix "./" (toString path)}";
in
{
  den.schema = {
    host = {
      imports = [
        {
          options.secrets = {
            file = lib.mkOption {
              description = "Encrypted SOPS file containing this host's secrets.";
              type = lib.types.path;
            };
            keyFile = lib.mkOption {
              default = "/var/lib/sops-nix/key.txt";
              description = "Absolute path to this host's age identity.";
              type = lib.types.str;
            };
          };
        }
      ];
      includes = [
        (
          { host, ... }:
          {
            nixos.sops = {
              age = {
                keyFile = host.secrets.keyFile;
                sshKeyPaths = lib.mkForce [ ];
              };
              defaultSopsFile = host.secrets.file;
            };
          }
        )
      ];
    };
    user = {
      imports = [
        {
          options.secrets = {
            file = lib.mkOption {
              description = "Encrypted SOPS file containing this user's secrets.";
              type = lib.types.path;
            };
            keyFile = lib.mkOption {
              default = ".config/sops/age/key.txt";
              description = "Path to this user's age identity, relative to their home unless absolute.";
              type = lib.types.str;
            };
          };
        }
      ];
      includes = [
        (
          { user, ... }:
          let
            homeSecrets = { config, ... }: {
              sops = {
                age.keyFile = homePath config.home.homeDirectory user.secrets.keyFile;
                defaultSopsFile = user.secrets.file;
              };
            };
          in
          {
            hjem = homeSecrets;
            homeManager = homeSecrets;
            provides.to-hosts.nixos =
              { config, ... }:
              let
                name = "users/${user.name}/age_key";
              in
              {
                assertions = [
                  {
                    assertion = config.sops.defaultSopsFile != null;
                    message = "sops.secret ${name}: missing secrets.file on the host or user entity";
                  }
                ];
                sops.secrets.${name} = {
                  group = "users";
                  mode = "0600";
                  owner = user.name;
                  path = homePath config.users.users.${user.name}.home user.secrets.keyFile;
                  restartUnits = [ ];
                };
              };
          }
        )
      ];
    };
  };
}
