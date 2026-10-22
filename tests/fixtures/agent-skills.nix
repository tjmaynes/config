let
  flake = builtins.getFlake (toString ../..);
  lib = flake.inputs.nixpkgs.lib;
  agentSkills = import ../../lib/agent-skills.nix { inherit lib; };

  repoA = {
    name = "repo-a";
    source = ./agent-skills/repo-a;
    subdir = "skills";
  };
  repoB = {
    name = "repo-b";
    source = ./agent-skills/repo-b;
    subdir = "skills";
  };

  targets = repos: builtins.attrNames (agentSkills.buildHomeFiles repos);
  fails = value: !(builtins.tryEval (builtins.deepSeq value true)).success;
in
{
  discovers-valid-skills = targets [ repoA ] == [ ".agents/skills/alpha" ];
  filters-included-skills =
    targets [ (repoB // { include = [ "beta" ]; }) ] == [ ".agents/skills/beta" ];
  rejects-duplicate-repositories = fails (
    agentSkills.buildHomeFiles [
      repoA
      (repoA // { })
    ]
  );
  rejects-duplicate-targets = fails (
    agentSkills.buildHomeFiles [
      repoA
      repoB
    ]
  );
  rejects-missing-subdirectory = fails (
    agentSkills.buildHomeFiles [
      (repoA // { subdir = "missing"; })
    ]
  );
  rejects-duplicate-includes = fails (
    agentSkills.buildHomeFiles [
      (
        repoA
        // {
          include = [
            "alpha"
            "alpha"
          ];
        }
      )
    ]
  );
  rejects-unknown-includes = fails (
    agentSkills.buildHomeFiles [
      (repoA // { include = [ "unknown" ]; })
    ]
  );
  rejects-structurally-invalid-includes = fails (
    agentSkills.buildHomeFiles [
      (repoA // { include = [ "invalid" ]; })
    ]
  );
}
