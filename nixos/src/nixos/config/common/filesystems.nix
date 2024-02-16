{ config, pkgs, ... }:
{
  config = {
    fileSystems = {
      "/mnt/cloudinit" = {
        device = "/dev/sr0";
        fsType = "iso9660";
        options = [
          "nofail"
        ];
      };
      "/home" = {
        device = "/dev/disk/by-label/home";
        autoResize = true;
        fsType = "ext4";
      };
    };
    systemd = {
      tmpfiles.rules = [
        "d ${config.users.users.user.home} 0700 ${config.users.users.user.name} ${config.users.users.user.group} -"
      ];
    };
  };
}
