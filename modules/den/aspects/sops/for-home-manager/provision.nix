{ lib, ... }:
{
  den.aspects.sops.for-home-manager.provision =
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
}
