{ ... }:
{
  den.aspects.ssh = {
    hjem.files.".ssh/config".text = ''
      Include ~/.ssh/config.d/*
    '';

    nixos.services.openssh = {
      enable = true;
      ports = [ 2222 ];
      settings = {
        KbdInteractiveAuthentication = true;
        PasswordAuthentication = true;
        PermitRootLogin = "no";
        X11Forwarding = false;
      };
    };
  };
}
