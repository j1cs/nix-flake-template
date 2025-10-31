_: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    prezto = {
      enable = true;
      pmodules = [
        "environment"
        "terminal"
        "editor"
        "history"
        "directory"
        "spectrum"
        "utility"
        "completion"
        "history-substring-search"
        "ssh"
        "syntax-highlighting"
        "git"
        "fasd"
        "autosuggestions"
        "prompt"
      ];
      prompt.theme = "suse";
    };

    shellAliases = {
      la = "ls -la";
      ".." = "cd ..";
      "nix-switch" = "sudo darwin-rebuild switch --flake ~/.config/nix\\#__USERNAME__-__SYSTEM__";
      vim = "nvim";
      vi = "nvim";
      # Git aliases requested
      gst = "git status";
      gsts = "git status --short";
      gd = "git diff";
      gcl = "git clone --recursive";
      gadd = "git add --all";
      ga = "git add";
      glog = "git log --topo-order --pretty=format:%C(auto)%h%d %s %C(8)%cr %C(bold blue)%an";
      gl = "git pull";
      glr = "git pull --rebase";
      gp = "git push";
      gpo = "git push origin \"$(git-branch-current)\"";
      "gc!" = "gc --amend";
      "gcn!" = "gc! --no-edit";
      "gca!" = "gca --amend";
      "gcan!" = "gca! --no-edit";
      grb = "git rebase";
      grbc = "git rebase --continue";
      grba = "git rebase --abort";
      grbs = "git rebase --skip";
      grbi = "git rebase --interactive";
      gco = "git checkout";
      gcb = "git checkout -b";
      gnbf = "gitNewBranchFeature";
      gnbb = "gitNewBranchBugfix";
      gnbh = "gitNewBranchHotfix";
    };

    # Extra prezto/zsh configuration and helper functions
    initContent = ''
      # Git branch helpers
      gitNewBranchFeature() { git checkout -b feature/$1 }
      gitNewBranchBugfix() { git checkout -b bugfix/$1 }
      gitNewBranchHotfix() { git checkout -b hotfix/$1 }

      # 'gaa' needs parameters; implement as function instead of alias
      gaa() { git add -A :/ "$@" }

      # Prezto options (translated from provided block)
      zstyle ':prezto:*:*' color 'yes'
      zstyle ':prezto:module:editor' key-bindings 'emacs'
      zstyle ':prezto:module:terminal' auto-title 'yes'

      # Module load order is managed by Home Manager's pmodules

      # Keep current theme managed by HM (redhat); do not override here
      # zstyle ':prezto:module:prompt' theme 'powerlevel10k'

      # Misc examples kept from provided config (disabled by default)
      # zstyle ':prezto:module:history' histsize 10000
      # zstyle ':prezto:module:history' savehist 10000
    '';
  };
}
