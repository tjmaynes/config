{
  lib,
  pkgs,
  user,
  ...
}:
let
  mailboxDirectory = "${user.homeDirectory}/workspace/mailbox";
  syncICloudMail = pkgs.writeShellApplication {
    name = "sync-icloud-mail";
    runtimeInputs = [
      pkgs.offlineimap
      pkgs.notmuch
    ];
    text = ''
      offlineimap -c "$HOME/.config/offlineimap/config"
      notmuch new
    '';
  };
in
{
  home = {
    packages = [
      pkgs.offlineimap
      pkgs.mutt
      pkgs.notmuch
      pkgs.pass
      syncICloudMail
    ];

    activation.createICloudMailbox = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p -- "${mailboxDirectory}"
      run chmod 700 -- "${mailboxDirectory}"
    '';

    file = {
      ".notmuch-config".text = ''
        [database]
        path=${mailboxDirectory}

        [user]
        name=${user.fullName}
        primary_email=tj@tjmaynes.com

        [new]
        tags=unread;inbox;

        [maildir]
        synchronize_flags=false
      '';

      ".config/offlineimap/config".text = ''
        [general]
        accounts = iCloud
        pythonfile = ${user.homeDirectory}/.config/offlineimap/credentials.py

        [Account iCloud]
        localrepository = iCloud-Local
        remoterepository = iCloud-Remote

        [Repository iCloud-Local]
        type = Maildir
        localfolders = ${mailboxDirectory}

        [Repository iCloud-Remote]
        type = IMAP
        remotehost = imap.mail.me.com
        remoteport = 993
        remoteuser = tjmaynes
        ssl = yes
        sslcacertfile = ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
        readonly = true
        remotepasseval = get_password()
      '';

      ".config/offlineimap/credentials.py".text = ''
        import subprocess

        def get_password():
            return subprocess.check_output(
                ["${pkgs.pass}/bin/pass", "show", "mail/icloud/tj@tjmaynes.com"], text=True
            ).strip()
      '';

      ".mutt/muttrc".text = ''
        set mbox_type = Maildir
        set folder = "${mailboxDirectory}"
        set spoolfile = "${mailboxDirectory}/INBOX"
        set read_only = yes
        set sendmail = "/usr/bin/false"
        set from = "tj@tjmaynes.com"
        set use_from = yes
        source "${user.homeDirectory}/.mutt/dracula.muttrc"
      '';

      ".mutt/dracula.muttrc".text = ''
        # Dracula Theme for Mutt: https://draculatheme.com/
        # Source: https://github.com/dracula/mutt
        color error color231 color212
        color indicator color231 color241
        color markers color210 default
        color message default default
        color normal default default
        color prompt default default
        color search color84 default
        color status color141 color236
        color tilde color231 default
        color tree color141 default

        color index color210 default ~D
        color index color84 default ~F
        color index color117 default ~N
        color index color212 default ~Q
        color index color215 default ~T
        color index color141 default ~v

        color hdrdefault color117 default
        color header color231 default ^Subject:.*

        color attachment color228 default
        color body color231 default [\-\.+_a-zA-Z0-9]+@[\-\.a-zA-Z0-9]+
        color body color228 default (https?|ftp)://[\-\.,/%~_:?&=\#a-zA-Z0-9]+
        color body color231 default (^|[[:space:]])[*][^[:space:]]+[*]([[:space:]]|$)
        color body color231 default (^|[[:space:]])_[^[:space:]]+_([[:space:]]|$)
        color body color231 default (^|[[:space:]])/[^[:space:]]+/([[:space:]]|$)
        color quoted color61 default
        color quoted1 color117 default
        color quoted2 color84 default
        color quoted3 color215 default
        color quoted4 color212 default
        color signature color212 default
      '';

    };
  };
}
