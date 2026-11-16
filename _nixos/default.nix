{...}: {
  imports = [
    ./options.nix
    ./polkit.nix

    ./firewall.nix
    ./dns.nix

    ./daemon

    ./networkmanager.nix

    ./gui.nix
  ];
}
