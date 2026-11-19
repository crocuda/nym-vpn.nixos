{...}: {
  flake.nixosModules.default = {
    lib,
    config,
    pkgs,
    ...
  }:
    with lib; let
      core = import ../../_nixos/packages/core.nix {
        inherit lib;
        inherit config;
        inherit pkgs;
      };
      nym-vpn-core = core.nym-vpn-core;
    in {
      environment.systemPackages = with pkgs; [
        nym-vpn-core
        xdg-utils
        iproute2
        iptables
        nftables
        coreutils
      ];

      # NYM DAEMON
      systemd.services.nym-vpnd = {
        description = "nym-vpnd daemon";

        after = [
          "systemd-resolved.service"
          "NetworkManager.service"
        ];

        before = [
          "network-online.target"
        ];

        # bindsTo = mkDefault ["systemd-resolved.service"];
        # requires = ["systemd-resolved.service"];
        wants = ["systemd-resolved.service"];
        wantedBy = [
          "multi-user.target"
          "NetworkManager.service"
        ];

        # Required on NixOS:
        # upstream expects these networking tools in PATH.
        # Without this block, this setup reproduced:
        #
        # Error(TunDevice)
        path =
          [
            pkgs.iproute2
            pkgs.coreutils
          ]
          ++ (
            if config.networking.nftables.enable
            then [pkgs.nftables]
            else pkgs.iptables
          );

        startLimitBurst = 6;
        startLimitIntervalSec = 24;

        serviceConfig = let
          verbosity =
            {
              "error" = "";
              "warn" = "";
              "info" = "";
              "debug" = "-v";
              "trace" = "-vv";
            }.${
              config.services.nym-vpn.logLevel
            };
        in {
          ExecStart = "${nym-vpn-core}/bin/nym-vpnd -v run-as-service";
          # ExecStart = let
          #   name = "nym-vpnd-run";
          #   text = ''
          #     set -x
          #     ${nym-vpn-core}/bin/nym-vpnd ${verbosity} run-with-args
          #     # ${nym-vpn-core}/bin/nym-vpnd ${verbosity} run-as-service
          #   '';
          #   script = pkgs.writeShellScriptBin name text;
          # in "${script}/bin/${name}";

          Restart = "always";
          RestartSec = 2;

          # Required for tunnel creation.
          AmbientCapabilities = [
            "CAP_NET_ADMIN"
            "CAP_NET_RAW"
            "CAP_NET_BIND_SERVICE"
          ];
          CapabilityBoundingSet = [
            "CAP_NET_ADMIN"
            "CAP_NET_RAW"
            "CAP_NET_BIND_SERVICE"
          ];
          NoNewPrivileges = false;
          PrivateNetwork = false;
        };
      };

      systemd.services.nym-vpnd-dns = {
        enable = config.services.nym-vpn.autoconnect.enable;
        after = ["nym-vpnd.service"];

        serviceConfig = {
          Type = "oneshot";
          Restart = "on-failure";
          RestartSec = 2;

          ExecStart = with lib; let
            name = "nym-vpnd-set-dns-script";
            text =
              ''
                set -x
                ${nym-vpn-core}/bin/nym-vpnc lan set allow
                ${nym-vpn-core}/bin/nym-vpnc dns enable
              ''
              + (concatMapStrings
                (x: "${nym-vpn-core}/bin/nym-vpnc dns set --udp ${x}\n")
                config.services.nym-vpn.lan.nameservers);
            script = pkgs.writeShellScriptBin name text;
          in "${script}/bin/${name}";
        };
      };
    };
}
