{
  self,
  nym-vpn,
  ...
}: {
  nym-vpn.aspects = rec {
    default = nym-vpn;
    nym-vpn = {
      nixos = {user, ...}: {
        imports = [
          self.nixosModules.default
        ];
        services.nym-vpn.users = [user.userName];
      };
      sops = {
        nixos = {config, ...}: {
          services.nym-vpn = {
            account.secret.enable = true;
            autoconnect.enable = true;
          };
        };
      };
      gui = {
        nixos = {config, ...}: {
          services.nym-vpn.gui.enable = true;
        };
      };
    };
  };
}
