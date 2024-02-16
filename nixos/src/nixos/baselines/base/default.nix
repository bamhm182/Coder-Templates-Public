{ config, ... }:
{
  config.main = {
    services = {
      sshd.enable = true;
    };
    system = {
      hostname = "base";
      copyConfig = true;
    };
    users = {
      primaryUserCanSudo = true;
    };
  };
}
