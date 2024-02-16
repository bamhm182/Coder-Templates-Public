{ config, lib, pkgs, ... }:
let
  installNixosConfig = pkgs.writeShellScriptBin "install-nixos-config" ''
    [ $EUID != 0 ] && echo "You need to run this as root..." && exit 1
    [ $(${pkgs.findutils}/bin/find /etc/nixos -type f | ${pkgs.coreutils-full}/bin/wc -l) != 0 ] && echo "Files exist in /etc/nixos... Bailing..." && exit 2
    ${pkgs.rsync}/bin/rsync -azhL /etc/nixos.initial/ /etc/nixos/
    ${pkgs.coreutils-full}/bin/chown 1000:1000 /etc/nixos -R
    ${pkgs.findutils}/bin/find /etc/nixos -type f -exec ${pkgs.coreutils-full}/bin/chmod 0600 '{}' \;
    ${pkgs.findutils}/bin/find /etc/nixos -type d -exec ${pkgs.coreutils-full}/bin/chmod 0700 '{}' \;
    ${pkgs.gnused}/bin/sed -i 's/initialHostname/'$(${pkgs.nettools}/bin/hostname)'/g' /etc/nixos/flake.nix
  '';
in
{
  config = lib.mkIf config.main.system.copyConfig {
    environment.etc = {
      "nixos.initial/common".source = ./config/common;
      "nixos.initial/options".source = ./config/options;
      "nixos.initial/postCreation".source = ./config/postCreation;
      "nixos.initial/flake.lock".source = ./config/flake.lock;
      "nixos.initial/flake.nix".source = ./config/flake.nix;
      "nixos.initial/${config.main.system.hostname}.nix".source = ./baselines/${config.main.system.hostname}/default.nix;
    };
    systemd = {
      services = {
        "copy-nixos-config" = {
          enable = true;
          wantedBy = [ "machines.target" ];
          description = "Copy /etc/nixos.initial config to /etc/nixos";
          serviceConfig = {
            ExecStart = [
              "${installNixosConfig}/bin/install-nixos-config"
            ];
            Type = "oneshot";
          };
        };
      };
    };
  };    
}
