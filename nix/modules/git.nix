{ ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user.name = "nyx.rootwithkhandal";
      user.email = "priyansh@mail.khandal.xyz";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      fetch.prune = true;
      core.editor = "code --wait";
      color.ui = true;
      diff = {
        algorithm = "histogram";
      };
    };
  };
}