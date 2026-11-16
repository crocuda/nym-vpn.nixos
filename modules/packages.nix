{
  lib,
  config,
  pkgs,
  ...
}: let
  moduleName = "nym-vpn";
in {
  systems = lib.mkDefault lib.systems.flakeExposed;
  perSystem = {
    pkgs,
    system,
  }: {
    packages = rec {
      default = nym-vpn-core;

      networkmanager-nymvpn = let
      in
        pkgs.stdenv.mkDerivation {
          src = pkgs.fetchurl {
            url = "https://github.com/nymtech/nym-vpn-client";
          };
          installPhase = ''
            mkdir -p $out
          '';
        };
      # The VPN core/daemon and commandline utility.
      nym-vpn-core = let
        nymVpnCoreVersion = config.services.${moduleName}.core.version;
        sha256 = config.services.${moduleName}.core.sha256;
        system = "x86_64";
        # system = pkgs.stdenv.hostPlatform.system;
      in
        pkgs.stdenv.mkDerivation {
          pname = "nym-vpn-core";
          version = nymVpnCoreVersion;
          src = pkgs.fetchurl {
            url = "https://github.com/nymtech/nym-vpn-client/releases/download/nym-vpn-v${nymVpnCoreVersion}/nym-vpn-core-v${nymVpnCoreVersion}_linux_${system}.tar.gz";
            inherit sha256;
          };

          sourceRoot = "nym-vpn-core-v${nymVpnCoreVersion}_linux_x86_64";

          nativeBuildInputs = [
            pkgs.autoPatchelfHook
          ];

          # Required on NixOS:
          # without these tools in the service PATH,
          # NymVPN may fail at tunnel setup with: Error(TunDevice)
          # even when:
          # - /dev/net/tun exists
          # - tun kernel module is loaded
          # - the daemon runs as root
          buildInputs = [
            pkgs.stdenv.cc.cc.lib
            pkgs.glibc
            pkgs.openssl
            pkgs.dbus
            pkgs.libmnl
            pkgs.libnftnl
          ];

          installPhase = ''
            mkdir -p $out/bin

            install -m755 nym-vpnd $out/bin/nym-vpnd
            install -m755 nym-vpnc $out/bin/nym-vpnc

            if [ -f nym-exclude ]; then
              install -m755 nym-exclude $out/bin/nym-exclude
            fi

            cp -r * $out
          '';
        };

      # The desktop GUI.
      nym-vpn-app = let
        nymVpnAppVersion = config.services.${moduleName}.gui.version;
        sha256 = config.services.${moduleName}.gui.sha256;
        system = "amd64";
      in
        pkgs.appimageTools.wrapType2 {
          pname = "nym-vpn-app";
          version = nymVpnAppVersion;
          src = pkgs.fetchurl {
            url = "https://github.com/nymtech/nym-vpn-client/releases/download/nym-vpn-v${nymVpnAppVersion}/NymVPN_${nymVpnAppVersion}_${system}.AppImage";
            inherit sha256;
          };
          extraPkgs = pkgs:
            with pkgs; [
              xdg-utils
              gtk3
              glib
              webkitgtk_4_1
              libayatana-appindicator
            ];
        };
      # A desktop icon that lanched the gui.
      nym-vpn-desktop = pkgs.makeDesktopItem {
        name = "${moduleName}";
        desktopName = "NymVPN";
        exec = "${nym-vpn-app}/bin/nym-vpn-app -l %U";
        terminal = false;
        type = "Application";
        categories = [
          "Network"
          "Security"
        ];
        mimeTypes = [
          "x-scheme-handler/nymvpn"
          "x-scheme-handler/nym-vpn"
        ];
      };
    };
  };
}
