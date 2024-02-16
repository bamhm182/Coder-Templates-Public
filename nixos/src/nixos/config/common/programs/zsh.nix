{ config, lib, pkgs, ... }:
{
  programs = {
    zsh = {
      enable = true;
      syntaxHighlighting.enable = true;
      autosuggestions = {
        enable = true;
        highlightStyle = "fg=#555";
      };
    };
  };
}
