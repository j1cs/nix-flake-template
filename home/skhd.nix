{
  pkgs,
  lib,
  primaryUser,
  ...
}:
{
  home.file.".local/bin/yabai-notify".source = ./files/yabai-notify;
  home.file.".local/bin/yabai-notify".executable = true;

  home.file.".config/skhd/skhdrc".source = ./files/skhdrc;
  home.file.".config/skhd/skhdrc".executable = false;

  home.activation.reloadSkhd = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    /usr/bin/killall -USR1 skhd || true
  '';

  # Ensure a user LaunchAgent for skhd so it's started at login and after rebuilds
  home.file.".local/bin/skhd-wrapper".source = ./files/skhd-wrapper;
  home.file.".local/bin/skhd-wrapper".executable = true;

  home.file."Library/LaunchAgents/org.skhd.plist".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
    <string>org.skhd</string>
        <key>ProgramArguments</key>
        <array>
          <string>/Users/jcuzmar/.local/bin/skhd-wrapper</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
        <key>StandardOutPath</key>
        <string>/tmp/skhd.out.log</string>
        <key>StandardErrorPath</key>
        <string>/tmp/skhd.err.log</string>
      </dict>
      </plist>
  '';

  home.activation.installSkhdAgent = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    log=/tmp/hm-skhd-bootstrap.log
    echo "$(date): starting skhd launchctl bootstrap" >> "$log"
    tries=5
    delay=1
    success=1
    for i in $(seq 1 $tries); do
      if /bin/launchctl bootstrap gui/$(id -u) "$HOME/Library/LaunchAgents/org.skhd.plist"; then
        echo "$(date): bootstrap succeeded on attempt $i" >> "$log"
        success=0
        break
      else
        echo "$(date): bootstrap attempt $i failed" >> "$log"
        sleep $delay
        delay=$((delay * 2))
      fi
    done
    if [ $success -ne 0 ]; then
      echo "$(date): bootstrap failed after $tries attempts" >> "$log"
    fi
  '';
}
