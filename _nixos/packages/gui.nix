# Function that returns a set of packages
{
  lib,
  config,
  pkgs,
  ...
}: let
  # The desktop GUI.
  nym-vpn-app = let
    nymVpnAppVersion = config.services.ny-vpn.gui.version;
    sha256 = config.services.nym-vpn.gui.sha256;
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
    name = "nym-vpn-desktop";
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
in {
  inherit nym-vpn-app;
  inherit nym-vpn-desktop;
}
