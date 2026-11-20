# Function that returns a set of packages
{inputs, ...}: {
  flake.nixosModules.default = {
    pkgs,
    config,
    lib,
    self,
    ...
  }: let
    networkmanager-nymvpn = let
      nymVpnCoreVersion = config.services.nym-vpn.core.version;
      # sha256 = config.services.nym-vpn.core.sha256;
      sha256 = "sha256-UABxEQtT0Y2dWs5g6lolhD7a569MfM6j3vAXrQlxNuE=";
      system = "x86_64";
    in
      pkgs.rustPlatform.buildRustPackage rec {
        pname = "networkmanager-nymvpn";
        name = pname;

        description = "NetworkManager NymVPN plugin";
        passthru = {
          networkManagerPlugin = "VPN/nm-nymvpn-service.name";
          updateScript = pkgs.gnome.updateScript {
            packageName = pname;
            attrPath = "networkmanager-nymvpn";
          };
        };

        src =
          pkgs.fetchFromGitHub {
            owner = "nymtech";
            repo = "nym-vpn-client";
            rev = "nym-vpn-v${nymVpnCoreVersion}";
            inherit sha256;
          }
          + "/nym-vpn-core";

        patches = [./fix-paths.patch];
        postPatch = ''
          substituteInPlace crates/nym-nm-vpn-plugin/packaging/nm-nymvpn-service.name \
            --replace-fail @PLUGINDIR@ $out/lib/NetworkManager \
            --replace-fail @LIBEXECDIR@ $out/libexec
        '';

        cargoLock = {
          lockFile = src + "/Cargo.lock";
          outputHashes = {
            # HINT: can use lib.fakeHash when hash is unknown
            "nym-api-requests-1.22.3" = "sha256-DAGWQI4FJA/wPJ+MkzgcZFvKmhnAynEVFU729KeXwGA=";
            "nym-bridges-0.3.0" = "sha256-ybhWpqxymAe2ZzTofA+iHkm0MNQwKCa6WX4NbEr0HNo=";
          };
        };
        doCheck = false;

        ## TODO: Create the editor libraries
        buildPhase = ''
          cargo build --release -p nym-nm-vpn-plugin
          make -C crates/nym-nm-vpn-plugin/editor
        '';
        # See nym-nm-vpn-plugin/Cargo.toml for installation source -> target
        installPhase = ''
          SRC_PATH="/build/nym-vpn-core/crates/nym-nm-vpn-plugin"
          # EDITOR_PATH="$SRC_PATH/editor/build"
          PLUGIN_PATH="/build/nym-vpn-core/target/release"

          mkdir -p $out/libexec
          mkdir -p $out/lib/NetworkManager/{VPN,system-connections}
          mkdir -p $out/share/dbus-1/system.d

          # ls -alh $SRC_PATH
          # ls -alh $PLUGIN_PATH
          # ls -alh $SRC_PATH/editor
          # ls -alh $SRC_PATH/editor/build/

          # Copy executable
          install -m755 $PLUGIN_PATH/nm-nymvpn-service $out/libexec
          install -m755 $SRC_PATH/packaging/nm-nymvpn-auth-dialog $out/libexec
          # Copy config files
          # NetworkManager ignores keyfiles that are readable by others, hence 600.
          install -m644 $SRC_PATH/packaging/nm-nymvpn-service.name $out/lib/NetworkManager/VPN/nm-nymvpn-service.name
          install -m644 $SRC_PATH/packaging/nm-nymvpn-service.conf $out/share/dbus-1/system.d/nm-nymvpn-service.conf
          install -m600 $SRC_PATH/packaging/NymVPN.nmconnection $out/lib/NetworkManager/system-connections/NymVPN.nmconnection
          # Editor
          # default -m644
          install -m755 $SRC_PATH/editor/build/libnm-vpn-plugin-nymvpn.so $out/lib/NetworkManager
          install -m755 $SRC_PATH/editor/build/libnm-vpn-plugin-nymvpn-editor.so $out/lib/NetworkManager
          install -m755 $SRC_PATH/editor/build/libnm-gtk4-vpn-plugin-nymvpn-editor.so $out/lib/NetworkManager
        '';
        nativeBuildInputs = with pkgs; [
          networkmanager
          openssl
          pkg-config
          pkgs.rust-bin.stable.latest.default
          # Editor
          libnma
          libnma-gtk4
          gtk4
          gtk3
          glib
          glib-networking
        ];
        buildInputs = with pkgs; [
          networkmanager
          openssl
          pkg-config
          pkgs.rust-bin.stable.latest.default
          # Editor
          libnma
          libnma-gtk4
          gtk4
          gtk3
          glib
          glib-networking
        ];
        # Protoc
        PROTOBUF_LOCATION = "${pkgs.protobuf}";
        PROTOC = "${PROTOBUF_LOCATION}/bin/protoc";
        PROTOC_INCLUDE = "${PROTOBUF_LOCATION}/include";
      };

    autoconnect =
      if (builtins.hasAttr "autoconnect" config.services.nym-vpn)
      then config.services.nym-vpn.autoconnect.enable
      else false;
  in {
    nixpkgs.overlays = [inputs.rust-overlay.overlays.default];
    environment.systemPackages = [pkgs.rust-bin.stable.latest.default];

    networking.networkmanager.plugins = [
      networkmanager-nymvpn
    ];

    # Works!
    networking.networkmanager.ensureProfiles.profiles."NymVPN" = {
      connection = {
        id = "NymVPN";
        uuid = "d6e3779f-2e64-4757-99fa-3e20c26592e4";
        type = "vpn";
        autoconnect = autoconnect;
      };
      vpn = {
        service-type = "org.freedesktop.NetworkManager.nymvpn";
        timeout = 120;
      };
      ipv4 = {
        # gateway = "127.0.0.1";
        # dns = "9.9.9.9";
        auto-route-ext-gw = 0; #-1;
        method = "auto";
      };
      ipv6 = {
        # gateway = "::1";
        addr-gen-mode = "default";
        auto-route-ext-gw = 0; #-1;
        method = "auto";
      };
      proxy = {};
    };

    # Do not work!
    # environment.etc = {
    # "NetworkManager/sytem-connections/NymVPN.nmconnection".source = "${nm_plugin}/lib/NymVPN.nmconnection";
    #   "NetworkManager/system-connections/NymVPN.nmconnection".text = ''
    #     #
    #     # Distro-provided NetworkManager profile for NymVPN, installed read-only under
    #     # /usr/lib/NetworkManager/system-connections. The UUID is fixed so upgrades replace, not
    #     # duplicate, the profile. Everything about the tunnel is configured in the NymVPN app.
    #     #
    #     # The daemon does all routing. The plugin reports no IP config, and auto-route-ext-gw=false stops
    #     # NetworkManager from adding its route to the VPN gateway (NetworkManager 1.42+).
    #     #
    #     [connection]
    #     id=NymVPN
    #     uuid=d6e3779f-2e64-4757-99fa-3e20c26592e4
    #     type=vpn
    #     autoconnect=${lib.trivial.boolToString autoconnect}
    #
    #     [vpn]
    #     service-type=org.freedesktop.NetworkManager.nymvpn
    #     timeout=120
    #
    #     [ipv4]
    #     auto-route-ext-gw=0
    #     method=auto
    #
    #     [ipv6]
    #     addr-gen-mode=default
    #     auto-route-ext-gw=0
    #     method=auto
    #
    #     [proxy]
    #   '';
    # };
  };
}
