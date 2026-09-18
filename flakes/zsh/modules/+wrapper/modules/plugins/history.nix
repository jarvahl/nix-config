{ ... }:
{
  zsh.modules = [
    ({ config, lib, ... }:
      let
        cfg = config.history;
      in
      {
        options.history = {
          file = lib.mkOption {
            type = lib.types.str;
            default = "$HOME/.zsh_history";
            description = "HISTFILE path (zsh syntax — env-var expansion allowed).";
          };
          size = lib.mkOption {
            type = lib.types.int;
            default = 10000;
            description = "HISTSIZE — in-memory history limit.";
          };
          save = lib.mkOption {
            type = lib.types.int;
            default = 10000;
            description = "SAVEHIST — on-disk history limit.";
          };
        };

        config.zsh.rc = lib.mkOrder 40 ''
          HISTFILE="${cfg.file}"
          HISTSIZE=${toString cfg.size}
          SAVEHIST=${toString cfg.save}
          [[ -d "''${HISTFILE:h}" ]] || mkdir -p "''${HISTFILE:h}"
        '';
      })
  ];
}
