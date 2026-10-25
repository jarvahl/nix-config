{
  den,
  lib,
  self,
  ...
}:
let
  schema = {
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
            includes = with den.aspects.sops; [
              (from host.secrets.file)
              (keyFile host.secrets.keyFile)
            ];
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
          {
            includes = with den.aspects.sops; [
              (from user.secrets.file)
              (keyFile user.secrets.keyFile)
            ];
          }
        )
      ];
    };
  };
in
lib.mkMerge [
  { den.schema = schema; }
  (
    let
      settings =
        kind: config:
        (lib.evalModules {
          modules = schema.${kind}.imports ++ [ { secrets = config; } ];
        }).config.secrets;

      hostTest = host: user: {
        expected = {
          hostFile = toString (../. + "/${host}+/host.sops.yaml");
          hostKeyFile = "/var/lib/sops-nix/key.txt";
          provisionedKey = {
            group = "users";
            mode = "0600";
            owner = user;
            path = "/home/${user}/.config/sops/age/key.txt";
          };
          sshKeyPaths = [ ];
          userFile = toString (../. + "/${host}+/user-${user}.sops.yaml");
          userKeyFile = "/home/${user}/.config/sops/age/key.txt";
        };
        expr =
          let
            config = self.nixosConfigurations.${host}.config;
            home = config.hjem.users.${user};
          in
          {
            hostFile = toString config.sops.defaultSopsFile;
            hostKeyFile = config.sops.age.keyFile;
            provisionedKey = builtins.intersectAttrs {
              group = null;
              mode = null;
              owner = null;
              path = null;
            } config.sops.secrets."users/${user}/age_key";
            sshKeyPaths = config.sops.age.sshKeyPaths;
            userFile = toString home.sops.defaultSopsFile;
            userKeyFile = home.sops.age.keyFile;
          };
      };
    in
    {
      flake.tests.sopsSchema = {
        testCargo = hostTest "cargo" "nixos";
        testDvalin = hostTest "dvalin" "jarvahl";
        testGaia = hostTest "gaia" "nixos";
        testHostDefault = {
          expected = "/var/lib/sops-nix/key.txt";
          expr = (settings "host" { file = ./default.nix; }).keyFile;
        };
        testKeyFileOverrides = {
          expected = [
            "/var/lib/custom-age/key.txt"
            "/run/user-age/key.txt"
          ];
          expr =
            map
              (
                kind:
                (settings kind {
                  file = ./default.nix;
                  keyFile = if kind == "host" then "/var/lib/custom-age/key.txt" else "/run/user-age/key.txt";
                }).keyFile
              )
              [
                "host"
                "user"
              ];
        };
        testMissingFiles = {
          expected = [
            false
            false
          ];
          expr = map (kind: (builtins.tryEval (settings kind { }).file).success) [
            "host"
            "user"
          ];
        };
        testUserDefault = {
          expected = ".config/sops/age/key.txt";
          expr = (settings "user" { file = ./default.nix; }).keyFile;
        };
        testZero = hostTest "zero" "jarvahl";
      };
    }
  )
]
