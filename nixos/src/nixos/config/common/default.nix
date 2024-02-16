{ config, ... }:
{
  imports = [
    ./cloudInit.nix
    ./console.nix
    ./filesystems.nix
    ./networking.nix
    ./security.nix
    ./system.nix

    ./programs
    ./services
    ./users
  ];
}
