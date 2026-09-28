# Declarative Agent Skill Repositories

## Goal

Manage reusable agent skills from multiple Git repositories through the existing
Nix flake and Home Manager configuration. Skill sources must be reproducible,
shared by Gaia and Athena, independently selectable, and installed without an
imperative clone or update step.

The initial repositories are `obra/superpowers` and `tjmaynes/skills`. The
design must make adding another repository a single flake input plus one list
entry.

## Source management

Declare every skill repository as a top-level non-flake input:

```nix
superpowers = {
  url = "github:obra/superpowers";
  flake = false;
};

tjmaynes-skills = {
  url = "github:tjmaynes/skills";
  flake = false;
};
```

The repository `flake.lock` pins the exact revisions. The existing `make
update` target remains the only grouped update interface because it already
runs `nix flake update` and therefore refreshes all inputs. No separate
`update-skills` target or aggregator flake is needed.

## Repository declarations

Build a `skillRepos` list in `flake.nix` and pass it through system
`specialArgs` and Home Manager `extraSpecialArgs`:

```nix
skillRepos = [
  {
    name = "superpowers";
    source = superpowers;
    subdir = "skills";
  }
  {
    name = "tjmaynes-skills";
    source = tjmaynes-skills;
    subdir = "skills";
  }
];
```

Each entry has these fields:

- `name`: required stable identifier used for diagnostics.
- `source`: required locked flake input path.
- `subdir`: optional repository-relative skills directory, defaulting to
  `skills`.
- `include`: optional list of skill directory names. When absent, install every
  structurally valid skill in the repository. When present, every entry must
  uniquely name a structurally valid skill; an unknown, malformed, or duplicate
  entry fails evaluation with the repository and skill names in the diagnostic.

Repository names are metadata and do not add another level to the installed
path.

## Home Manager installation

Add a focused shared Home Manager module for agent skills. For every repository
entry, it will inspect the configured source directory and select immediate
child directories whose `SKILL.md` entry is a regular file. If `include` is set,
it will retain only named children after validating every requested name.

This is intentionally structural validation only. The module does not parse or
validate YAML frontmatter or the Markdown instructions. Symlinked skill
directories and symlinked `SKILL.md` entries are not accepted, keeping discovery
behavior deterministic for locked source trees.

Install each selected skill as its own Home Manager file source:

```text
<repository>/skills/brainstorming -> ~/.agents/skills/brainstorming
```

Managing individual skill directories keeps `~/.agents/skills` available for
skills from other repositories or other Home Manager declarations. The linked
contents are immutable Nix store paths; upstream changes become visible only
after updating the lockfile and activating the new generation.

## Validation and failure behavior

The module will assert that:

1. Every repository `name` is unique.
2. No two selected repositories install the same target skill directory.
3. Every repository `include` list contains unique names and every name resolves
   to a structurally valid immediate skill directory in that repository.

A collision fails evaluation instead of selecting a repository based on list
order. Users resolve collisions with `include` allowlists.

Without `include`, the module ignores files, unrelated directories, and
structurally invalid skill directories. A missing configured repository
subdirectory is an evaluation error because it indicates an upstream layout
change or incorrect configuration.

## Tests and verification

Contract tests will cover both host configurations and verify:

- Both non-flake inputs are declared.
- `skillRepos` reaches the shared Home Manager module on Gaia and Athena.
- At least one skill from each initial repository is exposed below
  `.agents/skills` on both hosts.
- Each representative `home.file` source equals the exact corresponding locked
  input path plus its configured subdirectory and skill name.
- The existing `make update` target still invokes an unqualified `nix flake
  update`, updating every input.
- Focused fixtures reject duplicate repository names, duplicate selected target
  names, missing repository subdirectories, duplicate `include` names, and
  unknown or structurally invalid included skills.
- Focused fixtures verify `include` filtering and the omission of files,
  unrelated directories, and structurally invalid skills when no allowlist is
  present.
- Failure fixtures assert useful diagnostic text where the module system makes
  it available.

Before handoff, run `make format-check`, `make lint`, `make test`, `make
eval-gaia`, and `make eval-athena` as required by the repository guide.

## Non-goals

- Installing complete Codex plugins, hooks, or MCP servers from these
  repositories.
- Updating skill repositories during Home Manager activation.
- Silently resolving duplicate skill names.
- Adding a separate flake that exists only to group skill inputs.
