{ config, pkgs, ... }:
let
  coderWrapper = pkgs.writeShellScriptBin "coder" ''
    eval ''${HOME}/.local/bin/coder $@
  '';
  initScript = pkgs.writeShellScriptBin "coder-agent-init" ''
    set -eux

    waitonexit() {
      echo "=== Agent script exited with non-zero code. Sleeping 24h to preserve logs..."
      ${pkgs.coreutils-full}/bin/sleep 86400
    }
    trap waitonexit EXIT

    BINARY_DIR="''${BINARY_DIR:-$(echo ''${HOME}/.local/bin)}"
    BINARY_NAME=coder

    while :; do
      [ -f ''${HOME}/.config/coder/url ] && export CODER_AGENT_URL="$(${pkgs.coreutils-full}/bin/cat ''${HOME}/.config/coder/url)" && break
      echo "Coder config missing... Trying again in 1 seconds..."
      ${pkgs.coreutils-full}/bin/sleep 1
    done
    export CODER_AGENT_AUTH="token"
    export CODER_AGENT_TOKEN_FILE="''${HOME}/.config/coder/token"
    export PATH="''${BINARY_DIR}:''${PATH}"

    BINARY_URL=''${CODER_AGENT_URL}/bin/coder-linux-amd64

    mkdir -p "''${BINARY_DIR}"
    cd "''${BINARY_DIR}"
    while :; do
      ${pkgs.curl}/bin/curl -fsSL --compressed "''${BINARY_URL}" -o "''${BINARY_NAME}" && break
      echo "Download failed... Trying again in 5 seconds..."
      ${pkgs.coreutils-full}/bin/sleep 5
    done
    ${pkgs.coreutils-full}/bin/chmod +x "''${BINARY_NAME}"

    if /run/wrappers/bin/sudo -n ${pkgs.libcap}/bin/capsh --has-p=CAP_NET_ADMIN; then
      /run/wrappers/bin/sudo -n ${pkgs.libcap}/bin/setcap CAP_NET_ADMIN=+ep ./''${BINARY_NAME} || true
    fi

    exec ''${BINARY_NAME} agent
  '';
in
{
  config = {
    environment.systemPackages = [
      coderWrapper
    ];
    systemd = {
      services = {
        "coder-agent" = {
          enable = true;
          serviceConfig = {
            ExecStart = [
              "${initScript}/bin/coder-agent-init"
            ];
            Restart = "always";
            RestartSec = "10";
            TimeoutStopSec = "90";
            KillMode = "process";
            OOMScoreAdjust = "-900";
            SyslogIdentifier = "coder-agent";
            User = config.users.users.user.name;
            Group = config.users.users.user.group;
          };
        };
        "coder-watchdog" = {
          serviceConfig = {
            ExecStart = [
              "${pkgs.systemd}/bin/systemctl restart coder-agent.service"
            ];
            Type = "oneshot";
          };
        };
      };
      paths = {
        "coder-watchdog" = {
          enable = true;
          wantedBy = [ "machines.target" ];
          pathConfig = {
            PathModified = [
              "${config.users.users.user.home}/.config/coder/"
            ];
            Unit = "coder-watchdog.service";
          };
        };
      };
    };
  };
}
