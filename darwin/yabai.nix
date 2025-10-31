{
  pkgs,
  ...
}:
{
  services.yabai = {
    enable = true;
    package = pkgs.yabai;
    enableScriptingAddition = false; # Set true only if SIP is disabled
    config = {
      focus_follows_mouse = "autoraise";
      mouse_follows_focus = "off";
      window_placement = "second_child";
      window_opacity = "off";
      window_opacity_duration = "0.0";
      window_topmost = "on";
      window_shadow = "float";
      active_window_opacity = "1.0";
      normal_window_opacity = "0.90";
      split_ratio = "0.50";
      auto_balance = "on";
      mouse_modifier = "alt";
      mouse_action1 = "move";
      mouse_action2 = "resize";
      layout = "bsp";
      top_padding = 0;
      bottom_padding = 0;
      left_padding = 0;
      right_padding = 0;
      window_gap = 5;
    };
    extraConfig = ''
      # rules: make some apps unmanaged (always float)
      yabai -m rule --add app="^System Settings$" manage=off
      yabai -m rule --add label="Finder" app="^Finder$" title="(Co(py|nnect)|Move|Info|Pref)" manage=off
      yabai -m rule --add label="Safari" app="^Safari$" title="^(General|(Tab|Password|Website|Extension)s|AutoFill|Se(arch|curity)|Privacy|Advance)$" manage=off
      yabai -m rule --add label="macfeh" app="^macfeh$" manage=off
      yabai -m rule --add label="App Store" app="^App Store$" manage=off
      yabai -m rule --add label="Activity Monitor" app="^Activity Monitor$" manage=off
      yabai -m rule --add label="Calculator" app="^Calculator$" manage=off
      yabai -m rule --add label="Dictionary" app="^Dictionary$" manage=off
      yabai -m rule --add label="mpv" app="^mpv$" manage=off
      yabai -m rule --add label="Software Update" title="Software Update" manage=off
      yabai -m rule --add label="About This Mac" app="System Information" title="About This Mac" manage=off
      yabai -m rule --add label="HHKB" app="HHKB Keymap Tool" title="About This Mac" manage=off      

      # signals
      yabai -m signal --add event=space_changed \
        action="osascript -e 'tell application \"Übersicht\" to refresh widget id \"pecan-workspace-jsx\"'"

      echo "yabai configuration loaded.."
    '';
  };
}
