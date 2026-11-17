{self, ...}: {
  nym-vpn.aspects = rec {
    default = nym-vpn;
    nym-vpn = {
      nixos = {
        config,
        user,
        ...
      }: {
        imports = [
          self.nixosModules.nym-vpn
        ];
        services.nym-vpn.users = [user.userName];
      };
      sops = {
        nixos = {
          config,
          user,
          ...
        }: {
          services.nym-vpn = {
            users = [user.userName];
            account.secret.enable = true;
            autoconnect.enable = true;
          };
        };
      };
      gui = {
        nixos = {
          config,
          user,
          ...
        }: {
          services.nym-vpn.gui.enable = true;
        };
      };
    };
  };
}
