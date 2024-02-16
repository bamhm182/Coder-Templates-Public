{ config, lib, ... }:
{
  options.main.services = {
    sshd = {
      enable = lib.mkEnableOption "enable sshd";
    };
  };
}
