# Function that returns a set of packages
{
  config,
  pkgs,
  lib,
  ...
}: let
  nm_plugin = let
    nymVpnCoreVersion = config.services.nym-vpn.core.version;
    sha256 = config.services.nym-vpn.core.sha256;
    system = "x86_64";
    # system = pkgs.stdenv.hostPlatform.system;
  in
    pkgs.stdenv.mkDerivation {
      pname = "networkManager-nymvpn";
      description = "NetworkManager NymVPN plugin";
      src = pkgs.fetchTarBall {
        url = "https://github.com/nymtech/nym-vpn-client/releases/download/nym-vpn-v${nymVpnCoreVersion}";
        inherit sha256;
      };
    };
in {
  inherit nm_plugin;
}
