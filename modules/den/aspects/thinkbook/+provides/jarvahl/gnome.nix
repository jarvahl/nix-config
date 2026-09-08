{ ... }:
{
  den.aspects.thinkbook = {
    provides.jarvahl = {
      hjem =
        { pkgs, ... }:
        let
          gnome = pkgs.writeShellApplication {
            name = "gnome";
            runtimeInputs = [ pkgs.systemd ];
            text = ''
              systemctl --user start nested-gnome.service
            '';
          };

          nestedGnome = pkgs.writeShellApplication {
            name = "nested-gnome";
            runtimeInputs = with pkgs; [ dbus gnome-shell coreutils ];
            excludeShellChecks = [ "SC2016" ];
            text = ''
                inner_display=gnome-nested-0
                outer_display="''${WAYLAND_DISPLAY:?nested-gnome requires an existing Wayland session}"

              exec dbus-run-session -- ${pkgs.runtimeShell} -c '
                inner_display="$1"
                outer_display="$2"

                WAYLAND_DISPLAY="$outer_display" ${pkgs.gnome-shell}/bin/gnome-shell \
                  --wayland \
                  --no-x11 \
                  --wayland-display="$inner_display" &
                shell_pid=$!

                socket="''${XDG_RUNTIME_DIR:?}/$inner_display"
                for _ in $(${pkgs.coreutils}/bin/seq 1 100); do
                  [ -S "$socket" ] && break
                  kill -0 "$shell_pid" 2>/dev/null || wait "$shell_pid"
                  ${pkgs.coreutils}/bin/sleep 0.1
                done

                if [ ! -S "$socket" ]; then
                  kill "$shell_pid" 2>/dev/null || true
                  wait "$shell_pid" 2>/dev/null || true
                  echo "nested-gnome: inner Wayland socket did not appear" >&2
                  exit 1
                fi

                WAYLAND_DISPLAY="$inner_display" \
                  ${pkgs.dbus}/bin/dbus-update-activation-environment WAYLAND_DISPLAY

                wait "$shell_pid"
              ' nested-gnome "$inner_display" "$outer_display"
            '';
          };
        in
        {
          packages = [ gnome ];

          systemd.services.nested-gnome = {
            description = "Nested GNOME Shell compositor";
            partOf = [ "wayland-session@hyprland\\x2duwsm.desktop.target" ];
            after = [ "wayland-session@hyprland\\x2duwsm.desktop.target" ];

            serviceConfig = {
              ExecStart = "${nestedGnome}/bin/nested-gnome";
              Restart = "no";
            };
          };
        };
    };
  };
}
