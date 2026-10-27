{ pkgsUnstable, ... }:
{
  programs.codex = {
    enable = true;
    package = pkgsUnstable.codex;
    mutableSettings = true;
    enableMcpIntegration = true;
    settings = {
      model = "gpt-6.1-terra";
      model_reasoning_effort = "medium";
      personality = "pragmatic";
      features.js_repl = true;
    };
  };
}
