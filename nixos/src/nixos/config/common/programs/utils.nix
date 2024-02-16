{ configs, pkgs, ... }:
{
  config = {
    environment.systemPackages = [
      pkgs.dig
      pkgs.file
      pkgs.git
      pkgs.python3
      pkgs.tmux
      pkgs.vim
      pkgs.wget
    ];
  };
}
