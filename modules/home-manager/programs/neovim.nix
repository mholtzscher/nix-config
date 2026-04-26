{
  pkgs,
  inputs,
  ...
}:
let
  # Shared LSP packages used by multiple editors
  lspPackages = import ../lsp-packages.nix { inherit pkgs; };

in
{
  programs.neovim = {
    enable = true;
    package = inputs.neovim-nightly.packages.${pkgs.stdenv.hostPlatform.system}.default;
    defaultEditor = true;
    # Pin the new defaults here so Home Manager upgrades stay quiet and explicit.
    withRuby = false;
    withPython3 = false;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    initLua = builtins.readFile ../files/neovim/init.lua;
    plugins = [
      pkgs.vimPlugins.nvim-treesitter.withAllGrammars
    ];
    extraPackages = lspPackages ++ [
      # Neovim-specific extras (not needed by Helix)
      pkgs.rust-analyzer
      pkgs.rustfmt
      pkgs.stylua # lua formatter
      pkgs.shfmt # bash/sh formatter
      # pkgs.harper # grammar checker
    ];
  };
}
