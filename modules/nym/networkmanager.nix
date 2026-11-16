# Function that returns a set of packages
{
  config,
  pkgs,
  lib,
  ...
}: {
  flake.nixosModules.nym-vpn.nixos = {...}: let
    plugin = import ./packages/nm_plugin.nix {
      inherit lib;
      inherit config;
      inherit pkgs;
    };
    nm_plugin = plugin.nm_plugin;
  in {
    networking.networkmanager.plugins = [
      # inputs.nixosModules.networkmanager-plugin
      nm_plugin
    ];
  };
}
