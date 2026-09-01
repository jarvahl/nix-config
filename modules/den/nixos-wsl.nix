{ den
, lib
, ...
}:
{
  den.aspects.wsl = {
    provides.to-users = {
      hjem = {
        rum.programs.git.settings.credential.helper =
          "/mnt/c/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe";
      };
    };

    wsl = {
      interop.register = true;
    };

    nixos = {
      programs.nix-ld.enable = true;
    };
  };

  # Policy: if wsl is enabled, include our extra settings automatically
  den.policies.wsl-extras =
    { host, ... }:
    lib.optional ((host.wsl or { }).enable or false) (den.lib.policy.include den.aspects.wsl);

  den.schema.host.includes = [ den.policies.wsl-extras ];

  flake-file.inputs.nixos-wsl.url = "github:nix-community/nixos-wsl";
}
