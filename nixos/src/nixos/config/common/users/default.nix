{ config, pkgs, ... }:
{
  config = {
    users = {
      allowNoPasswordLogin = true; # Credentials are configured after the fact, this setting allows the disk to be created with no usable users
      mutableUsers = false;
      groups.user = {
        name = config.users.users.user.name;
        gid = config.users.users.user.uid;
      };
      users = {
        root = {
          hashedPassword = "!";
        };
        user = {
          isNormalUser = true;
          hashedPassword = "!";
          shell = pkgs.zsh;
          name = config.main.users.primaryUsername;
          group = config.users.groups.user.name;
          uid = 1000;
          extraGroups = [ "wheel" ];
        };
      };
    };
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users = {
        user = { imports = [ ./user ]; };
      };
    };
  };
}
