{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      curl
      git
      tmux
      htop
      tree
      nerd-fonts.caskaydia-cove
      defaultbrowser
      docker-compose
      lazydocker
      freerdp
      colima
      maven
      gradle
      nixfmt-rfc-style
      fastfetch
      wget
      #yabai
      #skhd
      jq
      lsd
      vscode
    ];
  };
}
