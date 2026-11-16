{
  lib,
  inputs,
  pkgs,
  config,
  self,
  ...
}: {
  # flake = {
  #   nixosModules = rec {
  #     default = nym-vpn;
  #     nym-vpn =
  #       lib.mkDefault ({...}: {
  #       });
  # nixpkgs.overlays = [self.inputs.rust-overlay.overlays.default];
  # environment.systemPackages = [pkgs.rust-bin.stable.latest.default];
  # imports = [
  #   ../_nixos/default.nix
  # ];
  # };
  # networkmanager-plugin = import ../_nixos/packages/nm_plugin.nix {
  #   inherit pkgs;
  #   inherit self;
  # };

  # nym-vpn = pkgs.callPackage ../_nixos/default.nix {
  #   inherit lib;
  #   inherit pkgs;
  #   inherit config;
  # };
  #   };
  # };

  systems = lib.mkDefault lib.systems.flakeExposed;
  perSystem = {
    config,
    pkgs,
    system,
    lib,
    ...
  }: {
    _module.args.pkgs = lib.mkDefault (import self.inputs.nixpkgs {
      inherit system;
      overlays = [inputs.rust-overlay.overlays.default];
    });
    packages.networkmanager-plugin = let
      plugin = pkgs.callPackage ../_nixos/packages/nm_plugin.nix {
        inherit config;
        inherit pkgs;
        inherit lib;
      };
    in
      plugin.nm_plugin;
  };
}
