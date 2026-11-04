{ config, lib, ... }:
let
  hasEncryptedSecrets = builtins.pathExists config.sops.defaultSopsFile;
in
{
  sops = {
    defaultSopsFile = lib.mkDefault ../../secrets/athena.sops.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    useSystemdActivation = true;
    secrets = lib.mkIf hasEncryptedSecrets {
      tailscale-auth-key = {
        key = "TAILSCALE_AUTHKEY";
        owner = "root";
        group = "root";
        mode = "0400";
        restartUnits = [ "tailscaled-autoconnect.service" ];
      };
    };
  };

  warnings = lib.optional (!hasEncryptedSecrets) (
    "Athena: secrets/athena.sops.yaml is missing; automatic Tailscale enrollment is disabled. "
    + "Provision the encrypted file and include it in the flake source before activation."
  );

  services.tailscale = lib.mkIf hasEncryptedSecrets {
    authKeyFile = config.sops.secrets.tailscale-auth-key.path;
    # Apply the same preferences on first enrollment as on subsequent boots.
    extraUpFlags = config.services.tailscale.extraSetFlags;
  };

  systemd.services.tailscaled-autoconnect = lib.mkIf hasEncryptedSecrets {
    after = [ "sops-install-secrets.service" ];
    requires = [ "sops-install-secrets.service" ];
  };
}
