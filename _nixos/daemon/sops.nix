## Secrets management
{
  lib,
  config,
  pkgs,
  nym-vpn-core,
  ...
}:
with lib; let
  moduleName = "nymvpn";
in {
  imports = [
    # inputs.sops-nix.nixosModules.sops
  ];

  ## WARNING: setting secret_key here might expose it to the nix cache
  # You might want to set a systemd unit environment file to prevent this.
  sops.secrets."nymvpn/secret" = {
    owner = "root";
    group = "root";
    mode = "0440";
    # path = "/var/lib/nymvpn/secret";
  };

  # Auto-connect.
  # Only on nixos generation rebuild and if sops is enabled.
  #
  # Reads the secret, connect to nym account, then delete the secret.
  systemd.services.nym-vpnd = {
    after = mkMerge [
      (mkIf (
        (config.services.${moduleName}.account.secret.enable == true)
        # && (builtins.hasAttr "sops" options)
      ) ["sops-install-secrets.service"])
    ];

    serviceConfig = {
      ExecStartPost = with lib; let
        name = "nym-vpnd-connect-script";
        text =
          ''
            set -x
            set +e
          ''
          + (
            if (config.services.${moduleName}.account.secret.enable == true)
            # && (builtins.hasAttr "sops" options)
            then
              # Connect to account
              ''
                if [ -f "${config.sops.secrets."nymvpn/secret".path}" ]; then
                  NYM_SECRET=$(cat ${config.sops.secrets."nymvpn/secret".path})
                  NYM_SECRET=$(echo $NYM_SECRET)
                  ${nym-vpn-core}/bin/nym-vpnc account set "$NYM_SECRET"
                fi
              ''
              # Delete secret
              + ''
                if [ -f "${config.sops.secrets."nymvpn/secret".path}" ]; then
                  rm -rf ${config.sops.secrets."nymvpn/secret".path}
                fi
              ''
            else ""
          )
          + ''
            exit 0
          '';
        script = pkgs.writeShellScriptBin name text;
      in "${script}/bin/${name}";
    };
  };

  systemd.services.nym-vpnd.wants =
    if config.services.${moduleName}.autoconnect.enable
    then [
      "nym-vpnd-autoconnect.service"
    ]
    else [];
  systemd.services.nym-vpnd-autoconnect = {
    enable = config.services.${moduleName}.autoconnect.enable;
    after = ["nym-vpnd.service"];

    serviceConfig = {
      Type = "oneshot";
      Restart = "on-failure";
      RestartSec = 2;

      ExecStart = with lib; let
        name = "nym-vpnd-autoconnect-script";
        text = ''
          set -x
          ${nym-vpn-core}/bin/nym-vpnc connect --wait
        '';
        script = pkgs.writeShellScriptBin name text;
      in "${script}/bin/${name}";
    };
  };
}
