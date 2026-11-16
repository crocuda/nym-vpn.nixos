{
  self,
  inputs,
  ...
}: let
  moduleName = "nym-vpn";
in {
  imports = [
    (inputs.flake-parts.flakeModules.flakeModules or {})
    (inputs.flake-file.flakeModules.dendritic or {})
    (inputs.den.flakeModules.dendritic or {})
  ];

  ${moduleName}.aspects = rec {
    default = "${moduleName}";
    ${moduleName} = {
      nixos = {
        config,
        user,
        ...
      }: {
        imports = [
          self.nixosModules.default
        ];
        config.services.${moduleName}.users = [user.userName];
      };
    };
    ${moduleName}.sops = {
      nixos = {
        config,
        user,
        ...
      }: {
        imports = [
          self.nixosModules.default
        ];
        config.services.${moduleName} = {
          users = [user.userName];
          account.secret.enable = true;
          autoconnect.enable = true;
        };
      };
    };
    ${moduleName}.gui = {
      nixos = {
        config,
        user,
        ...
      }: {
        config.services.${moduleName}.gui.enable = true;
      };
    };
  };
}
