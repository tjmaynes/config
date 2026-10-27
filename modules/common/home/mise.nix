{
  programs.mise = {
    enable = true;
    globalConfig.tools = {
      direnv = "2.32.1";
      python = "3.14.7";
      node = "24.20.0";
      kubectl = "1.37.0";
      just = "1.43.1";
      go = "1.27.0";
    };
  };
}
