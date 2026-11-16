{
  lib,
  inputs,
  pkgs,
  config,
  self,
  ...
}: {
  flake = {
    # nixosModules = {
    #   default = {pkgs, ...}: {
    #     nixpkgs.overlays = [self.inputs.rust-overlay.overlays.default];
    #     environment.systemPackages = [pkgs.rust-bin.stable.latest.default];
    #   };
    # };
  };

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
    # _module.args.pkgs = import self.inputs.nixpkgs {
    #   inherit system;
    #   overlays = [inputs.rust-overlay.overlays.default];
    # };
    # packages.networkmanager-plugin = let
    #   plugin = pkgs.callPackage ../_nixos/packages/nm_plugin.nix {
    #     inherit config;
    #     inherit pkgs;
    #     inherit lib;
    #   };
    # in
    #   plugin.nm_plugin;
    packages.networkmanager-plugin = let
      nymVpnCoreVersion = config.services.nym-vpn.core.version;
      # sha256 = config.services.nym-vpn.core.sha256;
      sha256 = "sha256-UABxEQtT0Y2dWs5g6lolhD7a569MfM6j3vAXrQlxNuE=";
    in
      pkgs.rustPlatform.buildRustPackage rec {
        pname = "networkManager-nymvpn";
        name = pname;

        description = "NetworkManager NymVPN plugin";
        passthru = {
          networkManagerPlugin = "VPN/nm-nym-service.name";
        };
        src =
          pkgs.fetchFromGitHub {
            owner = "nymtech";
            repo = "nym-vpn-client";
            rev = "nym-vpn-v${nymVpnCoreVersion}";
            inherit sha256;
          }
          + "/nym-vpn-core";

        srcRoot = src + "/crates/nym-nm-vpn-plugin";
        cargoLock = {
          lockFile = src + "/Cargo.lock";

          outputHashes = {
            "nym-api-requests-1.22.3" = "sha256-DAGWQI4FJA/wPJ+MkzgcZFvKmhnAynEVFU729KeXwGA=";
            "nym-bridges-0.3.0" = "sha256-ybhWpqxymAe2ZzTofA+iHkm0MNQwKCa6WX4NbEr0HNo=";
            # can use lib.fakeHash;
          };
        };

        nativeBuildInputs = with pkgs; [
          pkg-config
        ];
        buildInputs = with pkgs; [
          openssl
          pkg-config
          pkgs.rust-bin.stable.latest.default
        ];
      };
  };
}
