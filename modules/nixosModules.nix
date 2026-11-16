{...}: let
  moduleName = "nym-vpn";
in {
  flake = {
    nixosModules = rec {
      default = "${moduleName}";
      ${moduleName} = ../_nixos/default.nix;
    };
  };
}
