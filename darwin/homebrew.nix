{ ... }:
{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade = true;
      cleanup = "zap";
    };

    caskArgs.no_quarantine = true;
    caskArgs.appdir = "/Applications";
    global.brewfile = true;

    # homebrew is best for GUI apps
    # nixpkgs is best for CLI tools
    casks = [
      # Browsers
      "microsoft-edge"
      "google-chrome"

      # Collaboration
      "microsoft-teams"

      "clipy"
      # dev
      "ghostty"
      "xquartz"
      "stats"
      "windsurf"
      "postman"
      "caffeine"
      "flameshot"
      "meld"
    ];
    brews = [
      # keep minimal CLI brews here only if needed; most moved to Nix
    ];
    taps = [
    ];
  };
}
