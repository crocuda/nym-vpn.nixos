{
  inputs,
  lib,
  ...
}: {
  imports = [
    (inputs.flake-parts.flakeModules.flakeModules or {})
    (inputs.flake-file.flakeModules.dendritic or {})
    (inputs.den.flakeModules.dendritic or {})
  ];
  flake-file.inputs = {
    ###################################
    ## NixOs pkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    ###################################
    ## Dendritic
    flake-file.url = lib.mkDefault "github:vic/flake-file";
    flake-parts.url = lib.mkDefault "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";
    den.url = "github:denful/den";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
