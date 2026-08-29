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
      diff.tool = "delta";
      gpg.program = "gpg2";
      pull.rebase = false;
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
  };
}
