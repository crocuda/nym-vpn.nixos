# Function that returns a set of packages
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  plugin = import ../packages/nm_plugin.nix {
    inherit lib;
    inherit config;
    inherit pkgs;
  };
  nm_plugin = plugin.nm_plugin;
in {
  networking.networmanager.plugins = [
    nm_plugin
  ];
}
