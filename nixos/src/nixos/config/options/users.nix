{ config, lib, ... }:
{
  options.main.users = {
    primaryUsername = lib.mkOption {
      default = "user";
      type = lib.types.str;
      description = "Username of user 1000";
    };
    primaryUserCanSudo = lib.mkEnableOption "allow the primary user to sudo";
  };
}
