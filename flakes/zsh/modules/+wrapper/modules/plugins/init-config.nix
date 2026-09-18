{ ... }:
{
  zsh.modules = [
    ({ config, lib, ... }:
      {
        options.initConfig = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = "Free-form zsh code, emitted near the end of the generated .zshrc.";
        };

        config.zsh.rc = lib.mkOrder 900 config.initConfig;
      })
  ];
}
