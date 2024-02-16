{ config, ... }:
{
  config = {
    programs = {
      vim = {
        enable = true;
        settings = {
          background = "dark";
          expandtab = true;
          ignorecase = true;
          shiftwidth = 4;
          tabstop = 4;
        };
      };
    };
  };
}
