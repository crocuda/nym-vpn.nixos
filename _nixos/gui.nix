# NYM GUI CLIENT
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  gui = import ../packages/core.nix {
    inherit lib;
    inherit config;
    inherit pkgs;
  };
  nym-vpn-app = gui.nym-vpn-app;
  nym-vpn-desktop = gui.nym-vpn-desktop;
in {
  config = mkMerge [
    (mkIf (config.services.nym-vpn.gui.enable == true)
      {
        environment.systemPackages = [
          nym-vpn-app
          nym-vpn-desktop
        ];
        # Needed only for the AppImage GUI client and browser/deep-link callbacks.
        # The Flatpak client should provide its own .desktop file and URI handlers.
        xdg.mime.enable = true;
        xdg.mime.defaultApplications = {
          "x-scheme-handler/nymvpn" = "nym-vpn.desktop";
          "x-scheme-handler/nym-vpn" = "nym-vpn.desktop";
        };
      })
  ];
}
