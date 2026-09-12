{ ... }:
{
  den.aspects.apex.provides.jarvahl.hjem = { pkgs, ... }: {
    files.".config/herdr/config.toml".text = ''
      onboarding = false

      [theme]
      name = "catppuccin"

      [theme.custom]
      sidebar_bg = "#181825"
      panel_bg = "#181825"
    '';

    packages = [ pkgs.herdr ];
  };
}
