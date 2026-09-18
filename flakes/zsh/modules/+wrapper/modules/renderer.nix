{ ... }:

{
  zsh.modules = [
    ({ config, lib, dag, ... }:
      let
        renderPlugin = p:
          lib.concatStringsSep "\n" (
            (map (s: "source ${p.package}/${s}") (lib.optional (p.source != null) p.source ++ p.sources))
            ++ (lib.optional (p.init != "") p.init)
          );

        toDagEntry = name: p: {
          inherit name;
          value = dag.entry {
            inherit (p) after before;
            data = renderPlugin p;
          };
        };

        renderPluginDag = plugins:
          dag.render {
            entries = lib.listToAttrs (lib.mapAttrsToList toDagEntry plugins);
          };

        optPluginsScript = renderPluginDag config.zsh.optPlugins;

        idleHookScript = ''
          autoload -Uz add-zsh-hook
          _nix_zsh_idle_check() {
            if (( KEYS_QUEUED_COUNT || PENDING )); then
              sched +1 _nix_zsh_idle_check
            else
              ${optPluginsScript}
            fi
          }
          _nix_zsh_idle_init() {
            add-zsh-hook -d precmd _nix_zsh_idle_init
            _nix_zsh_idle_check
          }
          add-zsh-hook precmd _nix_zsh_idle_init
        '';
      in
      {
        options.zsh.rc = lib.mkOption { type = lib.types.lines; internal = true; };
        config.zsh.rc = lib.mkOrder 50 ''
          ${renderPluginDag config.zsh.startPlugins}
          ${lib.optionalString (config.zsh.optPlugins != { }) idleHookScript}
        '';
      })
  ];
}
