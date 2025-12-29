{ inputs, ... }:
{
  # CLI tools feature group

  imports = [
    ./bat.nix
    ./eza.nix
    ./fd.nix
    ./fzf.nix
    ./ripgrep.nix
    ./jq.nix
    ./yazi.nix
    ./btop.nix
    ./bottom.nix
  ];

  # dev-tools-packages aspect (holds packages list)
  flake.modules.homeManager.dev-tools-packages =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        # Nix tools
        inputs.melt.packages.${pkgs.stdenv.hostPlatform.system}.default
        inputs.difftui.packages.${pkgs.stdenv.hostPlatform.system}.default
        google-cloud-sdk
        nodejs_24
        lua
        bun
        zig

        # Development tools
        buf
        cachix
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
        nixfmt-rfc-style
        neovim
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
      ];
    };
}
