{ ... }:
{
  den.aspects.heeler = {
    provides.to-hosts.nixos =
      { user, ... }:
      {
        users.users.${user.userName}.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDTXnQQGklGfuVThClIwW2xACyBCOg7QszK0GX4T1Fx5 heeler"
        ];
      };
  };
}
