# Shared package set
{
  flake.modules.homeManager.packages =
    {
      pkgs,
      inputs,
      isWork ? false,
      ...
    }:
    let
      inherit (pkgs) lib;
    in
    {
      home.packages =
        (with pkgs; [
          inputs.melt.packages.${pkgs.stdenv.hostPlatform.system}.default
          inputs.difftui.packages.${pkgs.stdenv.hostPlatform.system}.default
          inputs.ugh.packages.${pkgs.stdenv.hostPlatform.system}.default
          google-cloud-sdk
          nodejs_24
          lua
          zig
        ])
        ++ lib.optionals (!isWork) [
          inputs.grepai.packages.${pkgs.stdenv.hostPlatform.system}.default
        ]
        ++ (with pkgs; [
          buf
          cachix
          cookiecutter
          cruft
          codesnap
          dive
          dust
          glow
          gnused
          grpcurl
          gum
          hey
          httpie
          jc
          just
          kdlfmt
          ko
          kubernetes-helm
          nixfmt
          nil
          oras
          procs
          rm-improved
          slides
          sops
          statix
          tldr
          topiary
          tree-sitter
          tree-sitter-grammars.tree-sitter-nu
          vim
          websocat
          wget
          yq
        ]);
    };
}
