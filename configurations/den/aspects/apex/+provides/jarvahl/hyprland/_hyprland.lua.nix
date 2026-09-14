{ pkgs, ... }:
''
  hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1.0,
  })

  hl.config({
    general = {
      border_size = 0,
      gaps_in = 16,
      gaps_out = {
        top = 0,
        right = 90,
        bottom = 48,
        left = 90,
      },
    },
    decoration = {
      rounding = 14,
      rounding_power = 2,
      shadow = {
        enabled = true,
        range = 18,
        render_power = 3,
        color = 0xaa000000,
      },
    },
    misc = {
      background_color = 0xc8c0b4,
      disable_hyprland_logo = true,
      disable_splash_rendering = true,
      force_default_wallpaper = 0,
    },
  })

  hl.bind("SUPER + Q", hl.dsp.exec_cmd("${pkgs.foot}/bin/foot"))
  hl.bind("SUPER + B", hl.dsp.exec_cmd("${pkgs.firefox}/bin/firefox"))
  hl.bind("SUPER + C", hl.dsp.window.close())
  hl.bind("SUPER + M", hl.dsp.exit())
  local focus_mode_window = nil

  local function leave_focus_mode()
    if focus_mode_window ~= nil then
      hl.dispatch(hl.dsp.window.fullscreen({
        action = "unset",
        mode = "fullscreen",
        window = focus_mode_window,
      }))
    end
    focus_mode_window = nil
    hl.dispatch(hl.dsp.submap("reset"))
  end

  hl.bind("SUPER + SHIFT + F11", function()
    focus_mode_window = hl.get_active_window()
    if focus_mode_window == nil then
      return
    end

    hl.dispatch(hl.dsp.window.fullscreen({
      action = "set",
      mode = "fullscreen",
      window = focus_mode_window,
    }))
    hl.dispatch(hl.dsp.submap("focus-mode"))
  end)

  hl.define_submap("focus-mode", function()
    hl.bind("SUPER + Escape", leave_focus_mode)
  end)

  hl.on("window.close", function(window)
    if focus_mode_window ~= nil and window.address == focus_mode_window.address then
      focus_mode_window = nil
      hl.dispatch(hl.dsp.submap("reset"))
    end
  end)

  hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("${pkgs.brightnessctl}/bin/brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })
  hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("${pkgs.brightnessctl}/bin/brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
  hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
  hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("${pkgs.wireplumber}/bin/wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
  hl.bind("XF86AudioMute", hl.dsp.exec_cmd("${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
  hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })

  hl.exec_cmd("${pkgs.uwsm}/bin/uwsm finalize")
''
