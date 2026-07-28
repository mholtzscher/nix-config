{
  pkgs,
  user,
  ...
}:
let
  captureDisplayDebug = pkgs.writeShellApplication {
    name = "capture-display-debug";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      pciutils
      systemd
    ];
    text = ''
      set -u

      timestamp=$(date '+%Y%m%d-%H%M%S')
      output_root="$HOME/.local/state/display-debug"
      output_dir="$output_root/$timestamp"
      mkdir -p "$output_dir"

      section() {
        printf '\n=== %s ===\n' "$1"
      }

      {
        section "capture"
        date --iso-8601=seconds
        printf 'uptime: '
        uptime
        printf 'user: %s\n' "$USER"
        printf 'session: %s (%s)\n' "''${XDG_CURRENT_DESKTOP:-unknown}" "''${XDG_SESSION_TYPE:-unknown}"

        section "kernel"
        uname -a
        printf 'command line: '
        cat /proc/cmdline

        section "GPU"
        lspci -nnk | grep -A4 -Ei 'VGA|3D|Display' || true
        if command -v nvidia-smi >/dev/null 2>&1; then
          nvidia-smi || true
        fi

        section "versions"
        niri --version 2>&1 || true
        dms version 2>&1 || true

        section "services"
        systemctl --user --no-pager --full status niri.service dms.service 2>&1 || true
      } > "$output_dir/summary.txt" 2>&1

      {
        for connector in /sys/class/drm/card*-DP-* /sys/class/drm/card*-HDMI-*; do
          [ -e "$connector" ] || continue
          printf '\n=== %s ===\n' "$connector"
          for property in status enabled dpms modes; do
            if [ -r "$connector/$property" ]; then
              printf '%s: ' "$property"
              tr '\n' ' ' < "$connector/$property"
              printf '\n'
            fi
          done
        done
      } > "$output_dir/connectors.txt" 2>&1

      {
        section "niri outputs"
        niri msg outputs 2>&1 || true
        section "DMS outputs"
        dms randr 2>&1 || true
        section "DMS DPMS"
        dms dpms list 2>&1 || true
      } > "$output_dir/output-state.txt" 2>&1

      journalctl --user -b -u niri.service -u dms.service --since '-30 min' \
        --no-pager -o short-precise > "$output_dir/user-journal.txt" 2>&1 || true
      journalctl -k -b --since '-30 min' --no-pager -o short-precise \
        > "$output_dir/kernel-journal.txt" 2>&1 || true

      if [ -r /tmp/kvm-triage.log ]; then
        cp /tmp/kvm-triage.log "$output_dir/live-capture.txt"
      fi

      ln -sfn "$timestamp" "$output_root/latest"
      sync
      systemd-cat -t capture-display-debug echo "Display debug saved to $output_dir"
    '';
  };

  refreshDisplays = pkgs.writeShellScriptBin "refresh-displays" ''
    set -eu

    NIRI_MSG="${pkgs.niri}/bin/niri msg"

    # Step 1: Try Niri DPMS power cycle — this forces DisplayPort link re-negotiation
    # which is what KVMs need after switching back.
    if $NIRI_MSG action power-off-monitors 2>/dev/null; then
      sleep 1
      $NIRI_MSG action power-on-monitors
      echo "KVM recovery: DPMS power cycle completed via Niri"
      exit 0
    fi

    echo "Niri DPMS not available, trying wlr-randr fallback..." >&2

    # Step 2: Try wlr-randr as a fallback
    if command -v wlr-randr >/dev/null 2>&1; then
      for output in DP-1 HDMI-A-1; do
        if wlr-randr --output "$output" --off 2>/dev/null; then
          sleep 1
          wlr-randr --output "$output" --on 2>/dev/null || true
          echo "KVM recovery: cycled $output via wlr-randr"
        fi
      done
      exit 0
    fi

    echo "No display management tool available (niri/wlr-randr)" >&2
    exit 1
  '';
in
{
  # Wayland composition stack: Niri window manager + DankMaterialShell
  # This module manages the setup for the desktop environment
  # Niri is enabled by the native NixOS module in hosts/nixos/nixos-desktop/default.nix.

  environment.systemPackages = [
    captureDisplayDebug
    refreshDisplays
  ];

}
