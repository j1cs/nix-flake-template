{
  pkgs,
  inputs,
  self,
  primaryUser,
  javaVersion,
  ...
}:
{
  imports = [
    ./homebrew.nix
    ./settings.nix
    ./mise-rust189.nix
    #./yabai.nix
    inputs.home-manager.darwinModules.home-manager
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  # nix config
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # disabled due to https://github.com/NixOS/nix/issues/7273
      # auto-optimise-store = true;
    };
    enable = false; # using Determinate installer
  };

  nixpkgs.config.allowUnfree = true;

  # homebrew installation manager
  nix-homebrew = {
    user = primaryUser;
    enable = true;
    autoMigrate = true;
  };

  # home-manager config
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # Back up conflicting dotfiles (e.g., ~/.zshrc) instead of failing
    backupFileExtension = "backup";
    users.${primaryUser} = {
      imports = [
        ../home
      ];
      # Define stateVersion here to satisfy early Home Manager assertions
      home.stateVersion = "25.05";
    };
    extraSpecialArgs = {
      inherit
        inputs
        self
        primaryUser
        javaVersion
        ;
    };
  };

  # macOS-specific settings
  system.primaryUser = primaryUser;
  users.users.${primaryUser} = {
    home = "/Users/${primaryUser}";
    shell = pkgs.zsh;
  };
  environment = {
    variables = {
      DISPLAY = ":0";
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      RUST_BACKTRACE = "1";
    };
    systemPackages = with pkgs; [
      git
      #yabai
    ];
    # Intel uses /usr/local; Apple Silicon uses /opt/homebrew
    systemPath = [
      (if pkgs.stdenv.isAarch64 then "/opt/homebrew/bin" else "/usr/local/bin")
    ];
    pathsToLink = [ "/Applications" ];
  };

  # Yabai config is now in darwin/yabai.nix

  # Expose the mise-installed JDK to macOS java_home by creating a .jdk bundle
  # /Library/Java/JavaVirtualMachines/${javaVersion}.jdk/Contents -> ~/.local/share/mise/installs/java/${javaVersion}/Contents
  system.activationScripts.miseGraalJavaHome.text = ''
    set -e
    DEST_DIR="/Library/Java/JavaVirtualMachines/${javaVersion}.jdk"
    SRC_CONTENTS="/Users/${primaryUser}/.local/share/mise/installs/java/${javaVersion}/Contents"
    if [ -d "$SRC_CONTENTS" ]; then
      mkdir -p "$DEST_DIR"
      if [ -L "$DEST_DIR/Contents" ] || [ -e "$DEST_DIR/Contents" ]; then
        TARGET=$(readlink "$DEST_DIR/Contents" || true)
        if [ "$TARGET" != "$SRC_CONTENTS" ]; then
          rm -rf "$DEST_DIR/Contents"
          ln -s "$SRC_CONTENTS" "$DEST_DIR/Contents"
        fi
      else
        ln -s "$SRC_CONTENTS" "$DEST_DIR/Contents"
      fi
    else
      echo "JDK Contents not found at $SRC_CONTENTS; skipping macOS JAVA_HOME integration" >&2
    fi
  '';
}
