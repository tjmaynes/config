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
  rea = pkgs.buildNpmPackage rec {
    pname = "rea-agents";
    version = "6.9.0";
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/rea-agents/-/rea-agents-${version}.tgz";
      hash = "sha512-KqDn1UR5BMqHoQ3MGAnPuWiSKwgdFaz1L/uUNgrKt+1W8kPtgYP8AWEOXIF1lDIOBVyPuYIIst2iamo1Wf3r8g==";
    };
    npmDepsHash = "sha256-6hRmFRsPY6U5O0tpwA3mAUZIic5cO+M/kAs326Q3lNI=";
    # Frida's installer downloads an unpinned toolchain. Use its official,
    # hash-pinned N-API binary instead, and avoid running npm lifecycle scripts.
    fridaBinding = pkgs.fetchurl {
      url =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "https://github.com/frida/frida/releases/download/17.23.2/frida-v17.23.2-napi-v8-darwin-arm64.tar.gz"
        else
          "https://github.com/frida/frida/releases/download/17.23.2/frida-v17.23.2-napi-v8-linux-x64.tar.gz";
      hash =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "sha256-hQ+6Igotm2quKCrG3eN/SIR+c1l7egbWSHN/+a3cM0A="
        else
          "sha256-n6j2aM6R6wNxPoVk3k+PveIyIz7pHXKcFnc/3hHbrpU=";
    };
    nativeBuildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.autoPatchelfHook ];
    buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.stdenv.cc.cc.lib ];
    npmFlags = [ "--ignore-scripts" ];
    postConfigure = ''
      tar -xzf "$fridaBinding" -C node_modules/frida
    '';
    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      cd "$out/lib/node_modules/rea-agents/node_modules/frida"
      node --input-type=module -e 'await import("./build/src/frida.js")'
      runHook postInstallCheck
    '';
    dontNpmBuild = true;
    nodejs = pkgs.nodejs_24;
  };
in
{
  home.file =
    lib.mapAttrs (
      name: file:
      file
      // {
        onChange = "echo ${lib.escapeShellArg "Installed or updated agent skill: ${baseNameOf name}"}";
      }
    ) (agentSkills.buildHomeFiles skillRepos)
    // {
      ".agents/skills/reverse-engineer-anything".source =
        "${rea}/lib/node_modules/rea-agents/skills/reverse-engineer-anything";
    };

  home.packages = [
    rea
    pkgs.frida-tools
  ];

  programs.codex = {
    enable = true;
    package = aiPackages.codex;
    context = ./files/context.md;
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
    servers.rea = {
      command = "${rea}/bin/rea";
      args = [ "mcp" ];
    };
    servers.playwright.command = "${pkgs.playwright-mcp}/bin/playwright-mcp";
  };
}
