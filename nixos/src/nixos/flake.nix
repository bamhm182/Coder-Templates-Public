{
  description = "Coder OSS v2 NixOS Template";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    qcow2-import = {
      url = "./formats/qcow2.nix";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, nixos-generators, qcow2-import, ... }:
  {
    packages.x86_64-linux = let
      mkBaseline = baseline:
      nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        format = "qcow2";
        modules = [
          home-manager.nixosModules.home-manager {}

          ./baselines/${baseline}

          ./config/common
          ./config/options
          ./copyConfig.nix
        ];
        customFormats = { qcow2.imports = [ qcow2-import.outPath ]; };
      };
    in
    {
      default = self.packages.x86_64-linux.base;

      base = mkBaseline "base";
    };
  };
}
