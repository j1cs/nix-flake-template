{
  pkgs,
  lib,
  primaryUser,
  ...
}:
let
  # Toggle: set to false to disable Spotlight indexing for HM apps
  hmSpotlightIndexEnable = true;
  baseConfig = {
    imports = [
      ./packages.nix
      ./git.nix
      ./shell.nix
      ./mise.nix
      ./neovim.nix
      ./vscode.nix
      ./ghostty.nix
      #./skhd.nix
      ./tmux.nix
      #./yabai.nix
    ]
    ++ lib.optionals hmSpotlightIndexEnable [
      ./spotlight-index.nix
    ];

    # Minimal home fragment; tmux is configured in ./tmux.nix
    home.username = primaryUser;
    # Ensure the home directory option is set so home-manager can resolve paths
    home.homeDirectory = "/Users/${primaryUser}";
    home.stateVersion = "25.05";
    home.sessionVariables = {
      VISUAL = "nvim -u NONE";
    };

    # create .hushlogin file to suppress login messages
    home.file.".hushlogin".text = "";
  };
in
baseConfig
