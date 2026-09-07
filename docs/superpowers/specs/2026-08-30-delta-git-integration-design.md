# Delta Git Integration Design

## Goal

Make the shared Home Manager Git configuration follow Delta's recommended Git
integration while providing a readable default diff layout.

## Design

`programs.delta.enableGitIntegration = true` remains the single integration
boundary. Home Manager will manage Delta as Git's pager for diff, log, show,
and blame output, plus the interactive staging filter. The configuration will
not set `diff.tool`, because Delta is not being used as an external difftool.

Delta options will enable navigation between diff sections, side-by-side
rendering, and line numbers. Git merge conflicts will use `zdiff3`. Theme
selection remains automatic by leaving Delta's `dark` and `light` options
unset.

## Validation

The shared Home Manager evaluation and a focused contract test will verify the
Delta options, pager/filter integration, merge conflict style, and absence of
the obsolete `diff.tool` setting. Standard format, lint, shell contract, and
host evaluation checks will be run before handoff.

## Scope and Safety

This change affects only the shared workstation Git/Home Manager profile. It
does not activate either workstation, alter package inputs, change secrets, or
configure an external Git difftool.
