{
  inputs,
  den,
  ...
}: {
  imports = [
    (inputs.den.namespace "nym-vpn" true)
  ];
  _module.args.__findFile = den.lib.__findFile;
}
