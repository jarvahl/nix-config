{ lib, ... }:

let
  caBundle = "/etc/ssl/certs/ca-certificates.crt";
in
{
  den.aspects.certificates = {
    nixos = {
      environment.shellInit = "export SSL_CERT_FILE=${lib.escapeShellArg caBundle}";
    };
  };

  den.aspects.certificates.zscaler.nixos =
    { pkgs, ... }:
    {
      security.pki.certificateFiles = [
        "${pkgs.zscaler-cacert}/etc/ssl/certs/zscaler-ca.crt"
      ];
    };

  den.aspects.zscaler = { };
}
