# Personal Mac host-specific Home Manager config
{
  flake.modules.homeManager.hostPersonalMac =
    {
      pkgs,
      inputs,
      ...
    }:
    {
      home.packages = with pkgs; [
        code-cursor
        discord

        aerospace
        inputs.aerospace-utils.packages.${pkgs.stdenv.hostPlatform.system}.default
        mkalias
        pokemon-colorscripts-mac
      ];
    };
}
