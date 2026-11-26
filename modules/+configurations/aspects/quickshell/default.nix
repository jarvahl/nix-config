{ ... }:
{
  den.aspects.quickshell.hjem =
    {
      config,
      lib,
      pkgs,
      self',
      ...
    }:
    let
      widgetPackages = builtins.map (name: self'.packages.${name}) (
        builtins.filter (name: lib.hasPrefix "island-" name && name != "island-shell") (
          builtins.attrNames self'.packages
        )
      );
      quickshellConfig = pkgs.runCommand "dynamic-island-config" { nativeBuildInputs = [ pkgs.jq ]; } ''
        mkdir -p "$out/share/island"
        cp -r ${self'.packages.island-shell}/share/island/. "$out/share/island/"
        manifests="$TMPDIR/widgets.ndjson"
        : > "$manifests"
        for widget in ${lib.escapeShellArgs widgetPackages}; do
          for manifest in "$widget"/share/island/*/plugin.json; do
            [ -f "$manifest" ] || continue
            base="file://$(dirname "$manifest")/"
            jq -c --arg base "$base" '
              .component = ($base + .component)
              | if .source then .source = ($base + .source) else . end
            ' "$manifest" >> "$manifests"
          done
        done
        jq -s '.' "$manifests" > "$out/share/island/widgets.json"
      '';

      launcherToggle = pkgs.writeShellScriptBin "launcher-toggle" ''
        config="$HOME/.config/quickshell/dynamic-island/share/island/Host.qml"
        exec ${pkgs.quickshell}/bin/qs -p "$(${pkgs.coreutils}/bin/readlink -f "$config")" ipc --any-display call launcher toggle
      '';
    in
    {
      files.".config/quickshell/dynamic-island".source = quickshellConfig;

      packages = [
        pkgs.brightnessctl
        pkgs.gtk3
        pkgs.quickshell
        launcherToggle
      ];

      wayland.windowManager.hyprland.settings.bind =
        lib.mkIf config.wayland.windowManager.hyprland.enable
          (
            with lib.generators;
            [
              {
                _args = [
                  "SUPER + P"
                  (mkLuaInline ''hl.dsp.exec_cmd("launcher-toggle")'')
                ];
              }
            ]
          );

      systemd.services.quickshell-dynamic-island = {
        after = [ "wayland-session-waitenv.service" ];
        description = "Quickshell Dynamic Island";
        partOf = [ "graphical-session.target" ];
        restartTriggers = [ config.files.".config/quickshell/dynamic-island".source ];

        serviceConfig = {
          Environment = [
            "DYNAMIC_ISLAND_DEFAULT=clock"
            "PATH=${
              lib.makeBinPath [
                pkgs.brightnessctl
                pkgs.gtk3
              ]
            }:/etc/profiles/per-user/jarvahl/bin:/run/current-system/sw/bin"
          ];
          ExecCondition = ''${pkgs.runtimeShell} -c 'test "$XDG_CURRENT_DESKTOP" = Hyprland' '';
          ExecStart = "${pkgs.quickshell}/bin/qs -p ${
            config.files.".config/quickshell/dynamic-island".source
          }/share/island/Host.qml";
          Restart = "on-failure";
        };

        wantedBy = [ "graphical-session.target" ];
        wants = [ "wayland-session-waitenv.service" ];
      };
    };
}
