let
  flake = builtins.getFlake (toString ../..);
  # Model a repository whose real secrets have already been provisioned.
  athena = flake.nixosConfigurations.athena.extendModules {
    modules = [ { sops.defaultSopsFile = ./tailscale.sops.yaml; } ];
  };
  configured = athena.config;
  unconfigured =
    (athena.extendModules {
      modules = [
        { sops.defaultSopsFile = flake.inputs.nixpkgs.lib.mkForce ./absent-secrets/athena.sops.yaml; }
      ];
    }).config;
  secret = configured.sops.secrets.tailscale-auth-key;
  autoconnect = configured.systemd.services.tailscaled-autoconnect;
in
{
  unprovisioned = {
    inherit (unconfigured.services.tailscale) authKeyFile;
    inherit (unconfigured) warnings;
  };
  provisioned = {
    inherit (secret)
      key
      owner
      group
      mode
      path
      restartUnits
      ;
    inherit (configured.services.tailscale) authKeyFile extraUpFlags extraSetFlags;
    inherit (autoconnect) after requires wantedBy;
    inherit (configured.sops.age) sshKeyPaths;
    inherit (configured.sops) validateSopsFiles useSystemdActivation;
    toplevel = configured.system.build.toplevel.drvPath;
  };
}
