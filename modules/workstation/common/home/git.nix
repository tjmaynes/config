{ identity, ... }:
{
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user.name = identity.fullName;
      user.email = identity.email;
      init.defaultBranch = "main";
      core.editor = "vi";
      gpg.program = "gpg2";
      merge.conflictStyle = "zdiff3";
      pull.rebase = true;
      commit.gpgSign = false;
      alias = {
        co = "checkout";
        st = "status";
        lg = "log --graph --oneline --decorate";
        lol = "log --graph --decorate --oneline";
        lola = "log --graph --decorate --oneline --all";
        s = "status -s -uno";
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      "side-by-side" = true;
      "line-numbers" = true;
    };
  };
}
