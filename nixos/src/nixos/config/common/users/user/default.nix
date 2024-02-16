{ config, ... }:
{
  imports = [
    ./vim.nix
    ./zsh.nix
  ];

  config.home = {
    stateVersion = "22.11";
  };
}
