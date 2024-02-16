{ config, pkgs, ... }:
let
  parseCloudInit = pkgs.writeShellScriptBin "parse-cloud-init" ''
    [[ "''${EUID}" != "0" ]] && echo "This should be run as root..." && exit 1
    authorized_keys=$(${pkgs.jq}/bin/jq -r '.authorized_keys' /mnt/cloudinit/user-data | tr ',' '\n')
    echo ''${authorized_keys} > /etc/ssh/authorized_keys.d/user
 '';
in
{
  config = {
    environment.systemPackages = [
      parseCloudInit
    ];
    systemd.services = {
      parse-cloudinit = {
        enable = true;
        wantedBy = [ "local-fs.target" ];
        description = "Create files from cloud-init file";
        serviceConfig = {
          ExecStart = [
            "${pkgs.bashInteractive}/bin/bash ${parseCloudInit}/bin/parse-cloud-init"
          ];
          Type = "oneshot";
        };
      };
    };
  };
}
