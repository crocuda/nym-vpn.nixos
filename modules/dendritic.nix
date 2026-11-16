{
  self,
  inputs,
  ...
}: {
  imports = [
    (inputs.flake-parts.flakeModules.flakeModules or {})
    (inputs.flake-file.flakeModules.dendritic or {})
    (inputs.den.flakeModules.dendritic or {})
  ];

  nym-vpn.aspects = rec {
    default = nym-vpn;
    nym-vpn = {
      nixos = {
        config,
        user,
        ...
      }: {
        imports = [
          self.nixosModules.default
        ];
        config.services.nym-vpn.users = [user.userName];
      };
      sops = {
        nixos = {
          config,
          user,
          ...
        }: {
          imports = [
            self.nixosModules.default
          ];
          config.services.nym-vpn = {
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
          config.services.nym-vpn.gui.enable = true;
        };
      };
    };
  };
}
