{ config, osConfig, ... }:
{
  config.programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    syntaxHighlighting.enable = true;
    sessionVariables = {
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=#555";
    };
    initExtra = ''
      [[ ! -z "$SSH_TTY" ]] && [[ ! -z $(command -v tmux) ]] && [[ -z "$TMUX" ]] && (tmux attach -t ssh > /dev/null 2>&1 || tmux new -s ssh > /dev/null 2>&1)
    '';
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
      ];
      theme = "agnoster";
    };
  };
}
