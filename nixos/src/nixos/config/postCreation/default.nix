{ config, lib, modulesPath, ... }:
{
  imports = [
    "${toString modulesPath}/profiles/qemu-guest.nix"
  ];
  config = {
    boot = {
      loader.grub = {
        enable = true;
        devices = [ "/dev/vda" ];
      };
      initrd = {
        availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
        kernelModules = [ ];
      };
      kernelModules = [ ];
      extraModulePackages = [ ];
    };
    fileSystems = {
      "/" = {
        device = "/dev/vda3";
        fsType = "ext4";
      };
      "/boot" = {
        device = "systemd-1";
        fsType = "autofs";
      };
    };
    swapDevices = [ ];
    networking.useDHCP = lib.mkDefault true;
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    system.stateVersion = "23.11";
  };
}
