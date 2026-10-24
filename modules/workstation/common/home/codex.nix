{ pkgsUnstable, ... }:
{
  programs.codex = {
    enable = true;
    package = pkgsUnstable.codex;
    mutableSettings = true;
    enableMcpIntegration = true;
    settings = {
      model = "gpt-5.6-terra";
      model_reasoning_effort = "medium";
      personality = "pragmatic";
      features.js_repl = false;
    };
  };
}
