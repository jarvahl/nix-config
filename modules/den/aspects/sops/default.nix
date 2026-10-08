{ lib, ... }:
let
  loadSecretsFrom =
    class:
    {
      file,
      sshKeyPath ? null,
    }:
    {
      ${class}.sops = {
        defaultSopsFile = file;
      }
      // lib.optionalAttrs (sshKeyPath != null) {
        age =
          if class == "nixos" then
            {
              keyFile = lib.mkForce null;
              sshKeyPaths = [ sshKeyPath ];
            }
          else
            { sshKeyPaths = [ sshKeyPath ]; };
      };
    };

  provisionHome =
    {
      name,
      path,
      mode ? "0600",
    }:
    {
      homeManager =
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

  provisionNixos =
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
in
{
  den.aspects.sops.for-home-manager = {
    loadSecretsFrom = loadSecretsFrom "homeManager";
    provision = provisionHome;
  };

  den.aspects.sops.for-nixos = {
    loadSecretsFrom = loadSecretsFrom "nixos";
    provision = provisionNixos;
  };
}
