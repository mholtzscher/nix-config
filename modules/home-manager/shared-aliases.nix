{
  isWork ? false,
  ...
}:
{
  shellAliases = {
    # Cross-platform aliases
    ngc = "nix-collect-garbage -d";
    nfc = "nix flake check";

    of = "open-file";

    c = "clear";
    ll = "ls -al";
    ltd = "eza --tree --only-dirs --level 3";
    lg = "lazygit";
    n = "nvim";
    j = "just";
    ghd = "gh dash";

    clean = "git clean -Xdf";

    oc = if isWork then "sh ~/code/paytient/ai-container/opencode/start" else "opencode";
    # pi = if isWork then "sh ~/code/paytient/ai-container/pi/start" else "pi";

    pbj = "pbpaste | jq";

    sso = "aws_change_profile";

    tf = "terraform";

    foundry-mods-dry-run = "rsync -av --dry-run /home/michael/games/SteamLibrary/steamapps/common/FOUNDRY/Mods/modList.json wanda:/home/michael/stacks/new-foundry/data/server/Mods/modList.json";
    foundry-mods-sync = "rsync -av /home/michael/games/SteamLibrary/steamapps/common/FOUNDRY/Mods/modList.json wanda:/home/michael/stacks/new-foundry/data/server/Mods/modList.json";
  };
}
