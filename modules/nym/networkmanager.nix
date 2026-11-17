# Function that returns a set of packages
{
  inputs,
  lib,
  ...
}: {
  flake.nixosModules.nym-vpn = {
    pkgs,
    config,
    lib,
    self,
    ...
  }: let
    nymVpnCoreVersion = config.services.nym-vpn.core.version;
    # sha256 = config.services.nym-vpn.core.sha256;
    sha256 = "sha256-UABxEQtT0Y2dWs5g6lolhD7a569MfM6j3vAXrQlxNuE=";
    system = "x86_64";
    nm_plugin = pkgs.rustPlatform.buildRustPackage rec {
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
      # + "/nym-vpn-core/crate/nym-nm-vpn-plugin";

      # srcRoot = src + "/crates/nym-nm-vpn-plugin";

      # cargoDeps = pkgs.rustPlatform.importCargoLock {
      #   lockFile = src + "/Cargo.lock";
      #   # lockFile = src + "../../../Cargo.lock";
      # };

      cargoLock = {
        lockFile = src + "/Cargo.lock";
        # lockFile = src + "/nym-vpn-core" + "/Cargo.lock";
        # lockFile = src + "../../../Cargo.lock";
        outputHashes = {
          # HINT: can use lib.fakeHash when hash is unknown
          "nym-api-requests-1.22.3" = "sha256-DAGWQI4FJA/wPJ+MkzgcZFvKmhnAynEVFU729KeXwGA=";
          # "dotenvy-0.15.7" = lib.fakeHash;
          "nym-bridges-0.3.0" = "sha256-ybhWpqxymAe2ZzTofA+iHkm0MNQwKCa6WX4NbEr0HNo=";
        };
      };

      doCheck = false;

      ## TODO: Create the editor libraries
      buildPhase = ''
        cargo build --release -p nym-nm-vpn-plugin
        # make -C crates/nym-nm-vpn-plugin/editor
      '';
      installPhase = ''
        PLUGIN_PATH="/build/nym-vpn-core/crates/nym-nm-vpn-plugin"
        mkdir -p $out/bin
        # cp target/release/nym-nymvpn-service $out/bin
        # install -m755 target/release/build/nym-nymvpn-service $out/bin
        ls -alh /build
        ls -alh $PLUGIN_PATH
        cp -r $PLUGIN_PATH/* $out/bin
      '';

      nativeBuildInputs = with pkgs; [
        openssl
        pkg-config
        pkgs.rust-bin.stable.latest.default
      ];
      buildInputs = with pkgs; [
        # networkmanager
        openssl
        pkg-config
        pkgs.rust-bin.stable.latest.default
      ];
      # Protoc
      PROTOBUF_LOCATION = "${pkgs.protobuf}";
      PROTOC = "${PROTOBUF_LOCATION}/bin/protoc";
      PROTOC_INCLUDE = "${PROTOBUF_LOCATION}/include";
    };
  in {
    nixpkgs.overlays = [inputs.rust-overlay.overlays.default];
    environment.systemPackages = [pkgs.rust-bin.stable.latest.default];
    networking.networkmanager.plugins = with pkgs; [
      # self'.packages.networkmanager-plugin
      # networkmanager-openvpn
      nm_plugin
    ];
  };
}
