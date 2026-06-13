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
    # CodeSnap.nvim's prebuilt macOS generator links to Homebrew's pcre2 path.
    # Provide Nix pcre2 at runtime instead of installing pcre2 via Homebrew.
    extraWrapperArgs = pkgs.lib.optionals pkgs.stdenv.isDarwin [
      "--prefix"
      "DYLD_LIBRARY_PATH"
      ":"
      "${pkgs.lib.getLib pkgs.pcre2}/lib"
    ];
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
