{ den, lib, ... }:
{
  den.policies.host-to-nixos-wsl =
    { host, ... }:
    lib.optional ((host.wsl or { }).enable or false) (
      den.lib.policy.include {
        nixos = {
          boot.loader.grub.enable = false;
          wsl.interop.register = true;
        };
      }
    );

  den.schema.host.includes = [ den.policies.host-to-nixos-wsl ];

  flake-file.inputs.nixos-wsl.url = "github:nix-community/nixos-wsl";
}
