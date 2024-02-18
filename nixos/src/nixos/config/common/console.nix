{ config, pkgs, lib, ... }:
{
  config = {
    console = {
      font = "Lat2-Terminus16";
      useXkbConfig = true;
    };
    environment = {
      shells = [
        pkgs.bashInteractive
        pkgs.zsh
      ];
      systemPackages = [
        pkgs.rxvt_unicode
        pkgs.vim
      ];
      variables = {
        EDITOR = "vim";
      };
    };
    fonts.packages = [
      pkgs.hermit
      pkgs.source-code-pro
      pkgs.terminus_font
      pkgs.powerline-fonts
      (pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; })
    ];
    i18n = {
      defaultLocale = "en_US.UTF-8";
      supportedLocales = [
        "en_US.UTF-8/UTF-8"
      ];
      extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };
    };
  };
}
