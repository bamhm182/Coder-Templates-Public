{ config, ... }:
{
  config = {
    services.qemuGuest.enable = true;
  };
}
