{ ... }:
{
  den.aspects.linger.nixos =
    { user, ... }:
    {
      users.users.${user.userName}.linger = true;
    };
}
