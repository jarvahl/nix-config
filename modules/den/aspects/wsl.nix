{ inputs, ... }:
{
  den.aspects.wsl = {
    provides.to-users = {
      hjem = {
        rum.programs.git.settings.credential.helper =
          "/mnt/c/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe";
      };
    };

    nixos = {
      imports = [ inputs.nixos-wsl.nixosModules.default ];
      wsl = {
        enable = true;
        interop.register = true;
      };
      boot.loader.grub.enable = false;
      programs.nix-ld.enable = true;
    };
  };

  flake-file.inputs.nixos-wsl.url = "github:nix-community/nixos-wsl";
}
