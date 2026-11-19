# Function that returns a set of packages
{
  config,
  pkgs,
  lib,
  ...
}: let
  # The VPN core/daemon and commandline utility.
  nym-vpn-core = let
    nymVpnCoreVersion = config.services.nym-vpn.core.version;
    sha256 = config.services.nym-vpn.core.sha256;
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
        # ls -alhg
        mkdir -p $out/bin

        install -m755 nym-vpnd $out/bin/nym-vpnd
        install -m755 nym-vpnc $out/bin/nym-vpnc

        if [ -f nym-exclude ]; then
          install -m755 nym-exclude $out/bin/nym-exclude
        fi

      '';
    };
in {
  inherit nym-vpn-core;
}
