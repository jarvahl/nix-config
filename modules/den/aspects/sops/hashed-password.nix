{ ... }:
{
  den.aspects.sops.hashedPassword.nixos =
    {
      config,
      lib,
      user,
      ...
    }:
    let
      userName = user.userName;
      secretName = "users/${userName}/hashed_password";
    in
    {
      assertions = [
        {
          assertion = config.sops.defaultSopsFile != null;
          message = "sops.hashedPassword ${userName}: missing secrets.file on the host entity";
        }
      ];

      sops.secrets.${secretName}.neededForUsers = true;

      users.mutableUsers = false;
      users.users.${userName} = {
        hashedPasswordFile = config.sops.secrets.${secretName}.path;
        initialPassword = lib.mkForce null;
      };
    };
}
