{
  lib,
  skillRepos,
  ...
}:

let
  agentSkills = import ../../../../lib/agent-skills.nix { inherit lib; };
in
{
  home.file = agentSkills.buildHomeFiles skillRepos;
}
