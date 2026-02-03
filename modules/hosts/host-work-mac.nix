# Work Mac host-specific Home Manager config
{
  flake.modules.homeManager.hostWorkMac =
    {
      pkgs,
      inputs,
      ...
    }:
    {
      home.packages = with pkgs; [
        aerospace
        inputs.aerospace-utils.packages.${pkgs.stdenv.hostPlatform.system}.default
        mkalias
        pokemon-colorscripts-mac
      ];
    };
}
