{ config, ... }:
{
  imports = [
    ./coder.nix
    ./qemuGuest.nix
    ./sshd.nix
  ];
}
