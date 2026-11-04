# Athena encrypted secrets

Only SOPS-encrypted files belong here. `athena.sops.yaml` is intentionally
absent until Athena's host recipient and a new enrollment key are available.
The flake emits an explicit warning and leaves automatic enrollment disabled
while that file is absent. No placeholder production key is provided.

Use a fresh Tailscale auth key for Athena. Do not reuse the home-server key.
The encrypted YAML must contain `TAILSCALE_AUTHKEY`. Its decrypted value is
installed root-owned with mode 0400 at `/run/secrets/tailscale-auth-key`.

## Provisioning

1. Generate or obtain Athena's persistent Ed25519 SSH host key on the machine
   during installation, before encrypting. Preserve that private key at
   `/etc/ssh/ssh_host_ed25519_key` in the installed system. If generating from
   the installer, use `/mnt/etc/ssh/ssh_host_ed25519_key` and preserve the
   corresponding public key. Never copy the private key into this repository.
2. Convert the **public** host key into an age recipient with the development
   shell's `ssh-to-age -i /path/to/ssh_host_ed25519_key.pub`. Keep an operator
   age recipient as well if you want to edit secrets from Gaia.
3. Create a new auth key in the Tailscale admin console. Select the tags,
   approval, and expiry appropriate for Athena. Do not paste it into chat,
   Nix source, a shell argument, or shell history.
4. Open an encrypted file using SOPS. Replace the public recipient list below
   with Athena's host recipient and, optionally, your operator recipient:

   ```sh
   nix develop
   sops --age 'age1ATHENA,age1OPERATOR' secrets/athena.sops.yaml
   ```

   In SOPS's local editor, enter `TAILSCALE_AUTHKEY: <the-new-auth-key>`.
   Saving writes ciphertext and SOPS metadata to the repository file.
   Use a trusted local editor that keeps its temporary files private.
5. Verify without revealing the key:

   ```sh
   sops filestatus secrets/athena.sops.yaml
   git add secrets/athena.sops.yaml
   make eval-athena
   ```

   Review only encrypted diffs. The host must be among the recipients, and
   its private host key must exist before the first SOPS-enabled activation.
   Nix evaluation checks wiring; it does not prove host-side decryption.

After an explicitly approved installation/activation, the upstream
`tailscaled-autoconnect.service` waits for `sops-install-secrets.service` and
enrolls the host. Existing Tailscale node state persists under `/var/lib/tailscale`;
normal rebuilds do not force re-enrollment. Replacing the auth key restarts the
autoconnect check without forcing an already-running node to log out.

Check `systemctl status sops-install-secrets tailscaled-autoconnect` and
`tailscale status` after activation. Never print the runtime secret file.

The encrypted fixture in `tests/fixtures/tailscale.sops.yaml` contains only a
fake, nonfunctional auth value encrypted to an upstream sops-nix test public
recipient. It is not production configuration and is never imported by Athena.
