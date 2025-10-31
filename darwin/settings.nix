{ self, ... }:
{
  # touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # system defaults and preferences
  system = {
    stateVersion = 6;
    configurationRevision = self.rev or self.dirtyRev or null;

    startup.chime = false;

    defaults = {
      loginwindow = {
        GuestEnabled = false;
        DisableConsoleAccess = true;
      };

      finder = {
        AppleShowAllFiles = true;
        AppleShowAllExtensions = true;
        _FXShowPosixPathInTitle = true;
        ShowPathbar = true;
        ShowStatusBar = true;
      };
      CustomUserPreferences = {
        "com.apple.SoftwareUpdate" = {
          AutomaticCheckEnabled = true;
          ScheduleFrequency = 1;
          AutomaticDownload = 1;
          CriticalUpdateInstall = 1;
        };
        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false;
        };
        "com.apple.CoreBrightness" = {
          AutomaticDisplayBrightness = 0;
          CBTrueToneEnabled = 0;
        };
        "com.apple.dock" = {
          mru-spaces = false;
        };
      };
      dock = {
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.25;
        show-recents = false;
      };

      NSGlobalDomain = {
        NSAutomaticSpellingCorrectionEnabled = false;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticWindowAnimationsEnabled = false;
        # Hide the native macOS menu bar so a custom status bar (e.g. spacebar)
        # can be used as the visible top bar. This mirrors the GUI setting
        # "Automatically hide and show the menu bar".
        _HIHideMenuBar = true;
      };
    };
  };

  # Set default browser to Microsoft Edge during activation (idempotent)
  system.activationScripts.setDefaultBrowser.text = ''
    if command -v defaultbrowser >/dev/null 2>&1; then
      echo "> Ensuring default browser is Microsoft Edge (com.microsoft.edgemac)"
      # Prefer bundle ID for reliability
      defaultbrowser com.microsoft.edgemac || true
    fi
  '';

  # Try to apply settings immediately after activation to avoid logout/login
  # `postUserActivation` was removed; activation now runs as root. Run
  # activateSettings -u for each user by switching to that user (sudo -u).
  system.activationScripts.postActivation.text = ''
    # activateSettings needs to run as the target user so that per-user
    # settings are applied. Iterate over /Users and run it for each real user.
    for dir in /Users/*; do
      [ -d "$dir" ] || continue
      user="$(basename "$dir")"
      # Skip common non-user directories
      case "$user" in
        Shared|Guest) continue ;;
      esac
      if id "$user" >/dev/null 2>&1; then
        echo "> Applying settings for user: $user"
        sudo -u "$user" /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u || true
      fi
    done
  '';
}
