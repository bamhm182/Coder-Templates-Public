{ config, lib, ... }:
{
  options.main.system = {
    hostname = lib.mkOption {
      type = lib.types.uniq lib.types.str;
      description = "hostname of the box";
    };
    copyConfig = lib.mkEnableOption "Copy NixOS Config into result VM";
  };
}
