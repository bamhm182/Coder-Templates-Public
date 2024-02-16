{ config, lib, ... }:
{
  config = {
    security.sudo.extraRules = [ ] ++
    (if config.main.users.primaryUserCanSudo then [
      {
        users = [ config.users.users.user.name ];
        runAs = config.users.users.root.name;
        commands = [
          {
            command = "ALL";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ] else [ ]);
  };
}
