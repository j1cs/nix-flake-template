{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true; # provide `vim` command
    viAlias = true; # provide `vi` command

    # Useful external tools for many plugins
    extraPackages = with pkgs; [
      ripgrep
      fd
      tree-sitter
      nodejs
      python3
      git
    ];
  };

  # Bootstrap ~/.config/nvim from your Git repo and update if clean.
  home.activation.nvimBootstrap =
    let
      dst = "$HOME/.config/nvim";
      repo = "https://github.com/j1cs/nvim.git";
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "> Ensuring Neovim config at ${dst} (repo: ${repo})"
      if [ ! -d "${dst}" ]; then
        echo "> Cloning ${repo} into ${dst}"
        "${pkgs.git}/bin/git" clone "${repo}" "${dst}" || true
      else
        if [ -d "${dst}/.git" ]; then
          current_remote=$("${pkgs.git}/bin/git" -C "${dst}" remote get-url origin 2>/dev/null || true)
          if [ "$current_remote" = "${repo}" ]; then
            # Only update if working tree is clean
            if "${pkgs.git}/bin/git" -C "${dst}" diff --quiet && [ -z "$(${pkgs.git}/bin/git -C "${dst}" status --porcelain)" ]; then
              echo "> Updating ${dst} (git pull --ff-only)"
              "${pkgs.git}/bin/git" -C "${dst}" pull --ff-only || true
            else
              echo "> Skipping update: local changes present in ${dst}"
            fi
          else
            echo "> Skipping update: origin is $current_remote, not ${repo}"
          fi
        else
          echo "> ${dst} exists and is not a git repo; leaving as-is"
        fi
      fi
      chmod -R u+rwX "${dst}"
    '';
}
