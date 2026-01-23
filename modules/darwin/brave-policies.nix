# Darwin module for Brave browser policies
# Writes policies to /Library/Managed Preferences/com.brave.Browser.plist
# Uses launchd daemon for persistence across reboots
{ pkgs, ... }:
let
  policies = import ../shared/brave-policies.nix;
  plist = pkgs.formats.plist { };
  policyPlist = plist.generate "com.brave.Browser.plist" policies;

  restoreScript = pkgs.writeShellScript "restore-brave-policies" ''
    set -euo pipefail
    src="${policyPlist}"
    target="/Library/Managed Preferences/com.brave.Browser.plist"

    # Only update if changed
    if [ -f "$target" ] && /usr/bin/cmp -s "$src" "$target"; then
      exit 0
    fi

    /usr/bin/install -d -m 0755 "/Library/Managed Preferences"
    /usr/bin/install -m 0644 "$src" "$target"

    # Required: reload preferences daemon for Brave to pick up changes
    /usr/bin/killall cfprefsd 2>/dev/null || true
  '';
in
{
  # Apply on every darwin-rebuild switch
  system.activationScripts.postActivation.text = ''
    ${restoreScript}
  '';

  # Launchd daemon ensures persistence (re-applies if directory changes)
  launchd.daemons.brave-policy-restore = {
    serviceConfig = {
      Label = "org.nix.brave-policy-restore";
      ProgramArguments = [ "${restoreScript}" ];
      RunAtLoad = true;
      WatchPaths = [ "/Library/Managed Preferences" ];
    };
  };
}
