{
  lib,
  llm-agents,
  pkgs,
  skillRepos,
  ...
}:
let
  agentSkills = import ../../../lib/agent-skills.nix { inherit lib; };
  aiPackages = llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  home.file = agentSkills.buildHomeFiles skillRepos;

  programs.codex = {
    enable = true;
    package = aiPackages.codex;
    mutableSettings = true;
    enableMcpIntegration = true;
    settings = {
      model = "gpt-6.1-terra";
      model_reasoning_effort = "medium";
      personality = "pragmatic";
      features.js_repl = true;
    };
  };

  programs.mcp = {
    enable = true;
    servers.n8n.url = "https://n8n.tjmaynes.com/mcp-server/http";
    servers.playwright.command = "${pkgs.playwright-mcp}/bin/playwright-mcp";
  };
}
