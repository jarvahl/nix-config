{ ... }:

{
  zsh.modules = [
    ({ config, ... }: {
      config.assertions = [
        {
          assertion = ! (config.syntaxHighlighting.integrations.patina.enable && config.zsh-syntax-highlighting.enable);
          message = "syntaxHighlighting.integrations.patina.enable and zsh-syntax-highlighting.enable are mutually exclusive.";
        }
      ];
    })
  ];
}
