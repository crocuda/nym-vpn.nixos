# Function that returns a set of packages
{
  inputs,
  self',
  ...
}: {
  flake.nixosModules.default = {
    pkgs,
    config,
    lib,
    ...
  }: let
    # plugin = pkgs.callPackage ../../_nixos/packages/nm_plugin.nix {
    plugin = self'.lib.nm_plugin {
      inherit lib;
      inherit config;
      inherit pkgs;
      inherit inputs;
    };
    nm_plugin = plugin.nm_plugin;
  in {
    nixpkgs.overlays = [inputs.rust-overlay.overlays.default];
    environment.systemPackages = [pkgs.rust-bin.stable.latest.default];
    networking.networkmanager.plugins = [
      # self'.packages.networkmanager-plugin
      nm_plugin
    ];
  };
}
