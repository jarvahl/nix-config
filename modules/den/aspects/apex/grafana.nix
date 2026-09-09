{ ... }:
{
  den.aspects.apex.nixos =
    { config, ... }:
    {
      services.grafana = {
        enable = true;
        settings.security.secret_key = "$__file{${config.sops.secrets."grafana/secret-key".path}}";
      };

      sops.secrets."grafana/secret-key".owner = "grafana";
    };
}
