{ pkgs, inputs, ... }:
{
  programs.vscode = {
    enable = true;
    # Use the Nix package for VS Code app. If you prefer the Homebrew cask, tell me and I can switch this off.
    package = pkgs.vscode;

    # Allow VS Code to manage marketplace extensions like Copilot
    mutableExtensionsDir = true;

    profiles.default = {
      # Extensions via nix-vscode-extensions (marketplace mirror)
      extensions = with inputs.nix-vscode-extensions.extensions.${pkgs.system}.vscode-marketplace; [
        # Languages
        golang.go
        ms-vscode.vscode-typescript-next
        esbenp.prettier-vscode
        dbaeumer.vscode-eslint

        # Git & tooling
        #github.vscode-pull-request-github
        #eamodio.gitlens

        # Nix
        jnoortheen.nix-ide
        arrterian.nix-env-selector

        # UX
        zhuangtongfa.material-theme
        pkief.material-icon-theme
      ];

      userSettings = {
        "files.associations" = {
          "*.tool.mod" = "go.mod";
          "*.tool.sum" = "go.sum";
        };
        "material-icon-theme.files.associations" = {
          "*.tool.mod" = "go-mod";
          "*.tool.sum" = "go-mod";
        };
        "workbench.colorTheme" = "One Dark Pro Night Flat";
        "workbench.iconTheme" = "material-icon-theme";
        "git.confirmSync" = false;
        "window.zoomLevel" = 0;
        "workbench.editor.enablePreview" = false;
        "workbench.startupEditor" = "newUntitledFile";
        "files.exclude" = {
          "**/.git" = true;
          "**/.DS_Store" = true;
          "**/.history" = true;
          "**/.pyc" = true;
          "**/.classpath" = true;
          "**/.project" = true;
          "**/.settings" = true;
          "**/.factorypath" = true;
          "**/bower_components" = true;
          "**/tmp" = true;
          "**/cache" = true;
        };
        "search.exclude" = {
          "**/.git" = true;
          "**/node_modules" = true;
          "**/bower_components" = true;
          "**/tmp" = true;
          "**/.history" = true;
          "**/cache" = true;
        };
        "window.titleBarStyle" = "custom";
        "explorer.confirmDelete" = false;
        "explorer.confirmDragAndDrop" = false;
        "go.docsTool" = "gogetdoc";
        "go.formatTool" = "gofmt";
        "go.autocompleteUnimportedPackages" = true;
        "editor.fontLigatures" = true;
        "explorer.decorations.badges" = false;
        "breadcrumbs.enabled" = false;
        "editor.minimap.enabled" = false;
        "go.toolsManagement.autoUpdate" = true;
        "github.authentication.useLocalServer" = true;
        "editor.fontFamily" = "'CaskaydiaCove Nerd Font','monospace', monospace";
      };
    };
  };
}
