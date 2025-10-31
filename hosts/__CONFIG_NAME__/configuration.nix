{
  pkgs,
  primaryUser,
  hostSuffix,
  ...
}:
{
  networking.hostName = "${primaryUser}-${hostSuffix}";
}
