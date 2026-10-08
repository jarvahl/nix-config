{ lib, ... }:
{
  den.aspects.sops = {
    for-hjem = {
      loadSecretsFrom =
        {
          file,
          sshKeyPath ? null,
        }:
        {
          hjem.sops = {
            defaultSopsFile = file;
          }
          // lib.optionalAttrs (sshKeyPath != null) {
            age.sshKeyPaths = [ sshKeyPath ];
          };
        };

      provision =
        {
          name,
          path,
          mode ? "0600",
        }:
        {
          hjem =
            { config, ... }:
            {
              sops.secrets.${name} = {
                inherit mode;
                path =
                  if lib.hasPrefix "/" (toString path) then
                    path
                  else
                    "${config.home.homeDirectory}/${lib.removePrefix "./" (toString path)}";
              };
            };
        };
    };

    for-nixos = {
      loadSecretsFrom =
        {
          file,
          sshKeyPath ? null,
        }:
        {
          nixos.sops = {
            defaultSopsFile = file;
          }
          // lib.optionalAttrs (sshKeyPath != null) {
            age = {
              keyFile = lib.mkForce null;
              sshKeyPaths = [ sshKeyPath ];
            };
          };
        };

      provision =
        {
          name,
          path,
          mode ? "0600",
          owner ? null,
          group ? null,
          restartUnits ? [ ],
        }:
        {
          nixos.sops.secrets.${name} = {
            inherit mode path restartUnits;
          }
          // lib.optionalAttrs (owner != null) { inherit owner; }
          // lib.optionalAttrs (group != null) { inherit group; };
        };
    };
  };
}
