{ lib, pkgs, ... }:
{
  imports = [ ../common/home ];
  home = {
    sessionVariables.EDITOR = "vim";
    activation.createWorkspace = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p -- "$HOME/workspace"
    '';
  };
  programs = {
    emacs.package = pkgs.emacs-nox;
    # Headless authentication uses a file, never a desktop keyring.
    codex.settings.cli_auth_credentials_store = "file";
  };
}
