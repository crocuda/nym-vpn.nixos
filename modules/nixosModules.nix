{...}: {
  flake = {
    nixosModules = rec {
      default = nym-vpn;
      nym-vpn = ../_nixos/default.nix;
    };
  };
}
