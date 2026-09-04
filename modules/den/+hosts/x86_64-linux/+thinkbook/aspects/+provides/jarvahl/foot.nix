{ ... }:
{
  den.aspects.thinkbook = {
    provides.jarvahl = {
      hjem = { pkgs, ... }: {
        files.".config/foot/foot.ini".text = ''
          [main]
          pad=16x16
          font=monospace:size=12
        '';

        packages = [ pkgs.foot ];
      };
    };
  };
}
