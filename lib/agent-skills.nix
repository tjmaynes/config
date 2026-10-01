{ lib }:

let
  duplicates =
    values:
    lib.unique (
      builtins.filter (
        value: builtins.length (builtins.filter (candidate: candidate == value) values) > 1
      ) values
    );

  formatNames = names: lib.concatStringsSep ", " names;

  repoRoot =
    repo:
    let
      source = repo.source.outPath or repo.source;
      subdir = repo.subdir or "skills";
    in
    "${source}/${subdir}";

  readRepo =
    repo:
    let
      root = repoRoot repo;
    in
    if !builtins.pathExists root then
      throw "Agent skill repository `${repo.name}` is missing configured subdirectory `${root}`."
    else
      {
        inherit root;
        entries = builtins.readDir root;
      };

  isValidSkill =
    root: entries: name:
    builtins.hasAttr name entries
    && entries.${name} == "directory"
    && (
      let
        skillEntries = builtins.readDir "${root}/${name}";
      in
      builtins.hasAttr "SKILL.md" skillEntries && skillEntries."SKILL.md" == "regular"
    );

  entriesForRepo =
    repo:
    let
      repoData = readRepo repo;
      include = repo.include or null;
      validSkills = lib.filterAttrs (
        name: _: isValidSkill repoData.root repoData.entries name
      ) repoData.entries;
      duplicateIncludes = if include == null then [ ] else duplicates include;
      invalidIncludes =
        if include == null then
          [ ]
        else
          builtins.filter (name: !(isValidSkill repoData.root repoData.entries name)) include;
      selectedSkills =
        if include == null then
          builtins.attrNames validSkills
        else if duplicateIncludes != [ ] then
          throw "Agent skill repository `${repo.name}` has duplicate include names: ${formatNames duplicateIncludes}."
        else if invalidIncludes != [ ] then
          throw "Agent skill repository `${repo.name}` includes unknown or invalid skills: ${formatNames invalidIncludes}."
        else
          include;
    in
    map (skillName: {
      name = ".agents/skills/${skillName}";
      repoName = repo.name;
      value.source = "${repoData.root}/${skillName}";
    }) selectedSkills;
in
{
  buildHomeFiles =
    repos:
    let
      repoNames = map (repo: repo.name) repos;
      duplicateRepos = duplicates repoNames;
      entries = lib.concatMap entriesForRepo repos;
      targetNames = map (entry: entry.name) entries;
      duplicateTargets = duplicates targetNames;
    in
    if duplicateRepos != [ ] then
      throw "Agent skill repository names must be unique; duplicates: ${formatNames duplicateRepos}."
    else if duplicateTargets != [ ] then
      throw "Agent skill target names must be unique; collisions: ${formatNames duplicateTargets}."
    else
      builtins.listToAttrs (
        map (entry: {
          inherit (entry) name value;
        }) entries
      );
}
