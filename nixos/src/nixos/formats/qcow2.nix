{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    "${toString modulesPath}/profiles/qemu-guest.nix"
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
  };

  boot = {
    growPartition = true;
    kernelParams = [ "console=ttyS0" ];
    loader = {
      timeout = 0;
      grub = {
        device =
          if (pkgs.stdenv.system == "x86_64-linux")
          then (lib.mkDefault "/dev/vda")
          else (lib.mkDefault "nodev");
        efiSupport = lib.mkIf (pkgs.stdenv.system != "x86_64-linux") (lib.mkDefault true);
        efiInstallAsRemovable = lib.mkIf (pkgs.stdenv.system != "x86_64-linux") (lib.mkDefault true);
      };
    };
  };

  system = {
    stateVersion = "23.11";
    build.qcow2 = import "${toString modulesPath}/../lib/make-disk-image.nix" {
      inherit lib config pkgs;
      diskSize = 65536;
      format = "qcow2-compressed";
      partitionTableType = "hybrid";
    };
  };

  formatAttr = "qcow2";
  fileExtension = ".qcow2";
}
