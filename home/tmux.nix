{
  pkgs,
  lib,
  primaryUser,
  ...
}:
{
  # Home Manager configuration for tmux kept in a separate file to keep
  # `home/default.nix` tidy.
  home = {
    # Install tmux for the user
    packages = with pkgs; [ tmux ];

    # Ensure TPM (tmux plugin manager) is present by cloning on activation
    activation.install-tpm = ''
      if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        echo "Cloning tmux plugin manager (tpm) to $HOME/.tmux/plugins/tpm"
        "${pkgs.git}/bin/git" clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
      fi
    '';
  };

  programs.tmux = {
    enable = true;
    extraConfig = ''
      # Use TPM installed in the user's home (cloned by activation)
      run "$HOME/.tmux/plugins/tpm/tpm"
      set -g @plugin 'tmux-plugins/tmux-resurrect'

      set -gq base-index 1
      set -gq focus-events on
      set -gq history-limit 10000
      set -gq set-titles on
      setw -gq aggressive-resize on
      setw -gq mode-keys vi
      setw -gq xterm-keys on
      # If you install tmux-resurrect later, you can enable capture with:
      # set -g @resurrect-capture-pane-contents 'on'
    '';
  };
}
