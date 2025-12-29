{ inputs, ... }:
{
  flake.modules.homeManager.helix =
    { pkgs, ... }:
    {
      programs.helix = {
        enable = true;
        defaultEditor = true;
        extraPackages = [
          pkgs.terraform-ls
          pkgs.dockerfile-language-server
          pkgs.docker-compose-language-service
          pkgs.yaml-language-server
          pkgs.marksman
          pkgs.kotlin-language-server
          pkgs.gopls
          pkgs.golangci-lint
          pkgs.golangci-lint-langserver
          pkgs.delve
          pkgs.nil
          pkgs.nixfmt-rfc-style
          pkgs.buf
          pkgs.bash-language-server
          pkgs.just-lsp
        ];
      };
    };
}
