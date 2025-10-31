{ primaryUser, ... }:
{
  programs.git = {
    enable = true;
    lfs.enable = true;

    ignores = [ "**/.DS_STORE" ];

    # HM 25.05 schema
    userName = "__USERNAME__";
    userEmail = "__USERNAME__@company.com";
    extraConfig = {
      github.user = primaryUser;
      init.defaultBranch = "main";
      core.editor = "nvim -u NONE";
    };
  };
}
