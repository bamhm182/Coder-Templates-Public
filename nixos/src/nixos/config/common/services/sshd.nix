{ config, lib, ... }:
{
  config = lib.mkIf config.main.services.sshd.enable {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        X11Forwarding = false;
        Ciphers = [
          "aes256-gcm@openssh.com"
          "aes256-ctr"
        ];
      };
      authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
      allowSFTP = true;
      extraConfig = ''
        AuthenticationMethods publickey
        AllowUsers ${config.users.users.user.name}
      '';
    };
    networking.firewall.allowedTCPPorts = [ 22 ];
    systemd.tmpfiles.rules = [
      "d /etc/ssh/authorized_keys.d/ 0755 root root -"
    ];
  };
}
