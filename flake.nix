{
  description = "A flake template for nix-darwin and Determinate Nix";

  # Flake inputs
  inputs = {
    # Stable Nixpkgs (use 0.1 for unstable)
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0";
    # Stable nix-darwin (use 0.1 for unstable)
    nix-darwin = {
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Determinate 3.* module
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Home Manager: pin to release matching Nixpkgs (25.05)
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nix-homebrew (as in starter)
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };

    # LazyVim starter (pinned via flake input, no sha256 needed here)
    lazyvim-starter = {
      url = "github:LazyVim/starter";
      flake = false;
    };
    # Rust overlay for pinning Rust toolchains
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # VS Code extensions as Nix
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Flake outputs
  outputs =
    { self, ... }@inputs:
    let
      # The values for `username` and `system` supplied here are used to construct the hostname
      # for your system, of the form `${username}-${system}`. Set these values to what you'd like
      # the output of `scutil --get LocalHostName` to be.

      # Your system username
      username = "__USERNAME__";

      # Your system type (Apple Silicon here)
      # Change this to `__SYSTEM__` for Intel macOS
      system = "__SYSTEM__";
      hostSuffix ="__HOST_SUFFIX__";
      # Central Java identifier used by mise and macOS java_home integration
      javaVersion = "temurin-25.0.1+8.0.LTS";
    in
    {
      # nix-darwin configuration output
      darwinConfigurations."${username}-${system}" = inputs.nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          # Determinate Nix module stays
          inputs.determinate.darwinModules.default

          # Existing local modules
          self.darwinModules.base
          self.darwinModules.nixConfig

          # Starter project modules (added safely)
          # Local copies under ~/.config/nix
          ./darwin
          ./hosts/${username}-${system}/configuration.nix
        ];
        specialArgs = {
          inherit
            inputs
            self
            javaVersion
            system
            hostSuffix
            ;
          primaryUser = username;
        };
        # Import nixpkgs for darwin with allowUnfree enabled so unfree packages
        # can be used by nix-darwin modules without requiring environment variables.
        pkgs = import inputs.nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };
      };

      # nix-darwin module outputs
      darwinModules = {
        # Some base configuration
        base =
          {
            config,
            pkgs,
            lib,
            ...
          }:
          {
            # Required for nix-darwin to work
            system.stateVersion = 1;

            users.users.${username} = {
              name = username;
              # See the reference docs for more on user config:
              # https://nix-darwin.github.io/nix-darwin/manual/#opt-users.users
            };

            # Other configuration parameters
            # See here: https://nix-darwin.github.io/nix-darwin/manual
          };

        # Nix configuration
        nixConfig =
          {
            config,
            pkgs,
            lib,
            ...
          }:
          {
            # Let Determinate Nix handle your Nix configuration
            nix.enable = false;
            # Custom Determinate Nix settings written to /etc/nix/nix.custom.conf
            determinate-nix.customSettings = {
              flake-registry = "/Users/${username}/.config/nix/flake-registry.json";
              # Enables parallel evaluation (remove this setting or set the value to 1 to disable)
              eval-cores = 0;
              extra-experimental-features = [
                "build-time-fetch-tree" # Enables build-time flake inputs
                "parallel-eval" # Enables parallel evaluation
              ];
            };
          };

        # Add other module outputs here
      };
      homeConfigurations = {
        "${username}-${system}" = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
            };
          };
          # Provide the home configuration as a module list and pass primaryUser
          # and javaVersion through extraSpecialArgs so the pinned home-manager can access them.
          modules = [ ./home/default.nix ];
          extraSpecialArgs = {
            inherit inputs;
            primaryUser = username;
            javaVersion = javaVersion;
          };
        };
      };
      # Nix formatter

      # This applies the formatter that follows RFC 166, which defines a standard format:
      # https://github.com/NixOS/rfcs/pull/166

      # To format all Nix files:
      # git ls-files -z '*.nix' | xargs -0 -r nix fmt
      # To check formatting:
      # git ls-files -z '*.nix' | xargs -0 -r nix develop --command nixfmt --check
      formatter.${system} = inputs.nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
    };
}
