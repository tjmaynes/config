# Workstation Nerd Fonts Design

## Goal

Give Gaia and Athena the same developer-font set: Nerd Font variants of
Iosevka, Inconsolata, and Blex Mono, plus Linux Libertine and Libre Baskerville
for proportional text. Blex Mono is the selected IBM Plex Mono Nerd Font
variant.

## Design

The Darwin preferences module and the NixOS desktop module will each declare
the same `fonts.packages` list:

```nix
with pkgs; [
  nerd-fonts.iosevka
  nerd-fonts.inconsolata
  nerd-fonts.blex-mono
  libertine
  libre-baskerville
]
```

The platform modules remain the ownership boundary for their operating
system's font installation. A shared module is unnecessary for two short,
explicit declarations and would add indirection without changing behavior.

The change replaces Athena's `corefonts` and non-Nerd `inconsolata` package.
It expands Gaia's current non-Nerd `inconsolata` package to the full list.
Athena's i3 bar will select `Inconsolata Nerd Font Mono`, so the existing
explicit font selection resolves to the newly installed Nerd Font family.
The shared Emacs configuration will select the same `Inconsolata Nerd Font
Mono` family for its default face, so the setting resolves consistently on both
hosts. Choosing Iosevka or Blex Mono as a new default remains out of scope.

## Validation

Add focused font package assertions to the Gaia and Athena contract tests. Each
assertion will evaluate `config.fonts.packages` to the package `pname` values
and require this identical ordered list: `nerd-fonts-iosevka`,
`nerd-fonts-inconsolata`, `nerd-fonts-blex-mono`, `linux-libertine`, and
`libre-baskerville`. This proves that the old Athena packages are not present.
The Athena contract test will also assert its i3 bar uses
`Inconsolata Nerd Font Mono`; the shared Home Manager contract test will assert
the Emacs setting uses that same family. Run the flake formatter check, lint
suite, shell contract tests, and both host evaluations. These checks verify the
declarations without activating either workstation.

## Scope and Safety

This change touches the Darwin and NixOS declarative font package lists,
Athena's i3 font-family selection, the shared Emacs default-face family, and
their focused contract tests. It does not activate Gaia or Athena, change flake
inputs, remove user files, or add font files or secrets to the repository.
