{ config, pkgs, ... }:
{
  config = {
    networking.hostName = config.main.system.hostname;
    nixpkgs.config.allowUnfree = true;
    nix = {
      settings = {
        allowed-users = [ config.users.users.user.name ];
        auto-optimise-store = true;
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [ config.users.users.user.name ];
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
    };
  };
}
