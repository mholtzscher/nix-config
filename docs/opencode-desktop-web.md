# OpenCode V2 web on nixos-desktop

The `opencode-web` user service runs OpenCode as Michael on loopback port 49374.
User lingering starts it before login and keeps it running after logout. The
desktop must remain powered on, awake, and connected to Tailscale.

OpenCode V2 is installed separately at `~/.bun/bin/opencode`; the Nixpkgs
`opencode` package in this flake is V1. Keep the Bun installation available
when updating the service.

## One-time setup

Do the handoff in a separate terminal, **not an OpenCode session connected to
the current background server**. Stop the existing server before applying the
NixOS configuration: both servers use port 49374. Do not use an apply command
from an agent; run the repository's normal switch command yourself. Close any
other connected clients during the handoff: they may automatically restart the
old managed server before the systemd unit can claim the port.

```sh
opencode service set hostname 127.0.0.1 # also stops the current server
# Apply the NixOS configuration yourself, then check the new user service:
systemctl --user status opencode-web
opencode service status
```

If `opencode-web` is inactive but `opencode service status` shows a running
server, a client won the startup race. The loopback server still works through
Tailscale Serve, but systemd is not supervising it. Close connected clients,
run `opencode service stop` and `systemctl --user start opencode-web` from a
separate terminal, then confirm the unit is active. The enabled unit should
also take ownership on the next boot, before clients connect.

The systemd service uses `serve --service`, so it reads the existing private
OpenCode service configuration (including the password). Do not put the
password in Nix or this repository. To replace it, run
`opencode service set password '<your-new-password>'` yourself before applying;
keep it private.

With the OpenCode service running, publish it through Tailscale Serve. This
preserves existing Serve routes on other ports and survives Tailscale restarts.
Tailscale may prompt you to enable HTTPS certificates for your tailnet.

```sh
tailscale serve --bg --https=443 127.0.0.1:49374
tailscale serve status
opencode pair --url https://nixos-desktop.tailea9b59.ts.net
```

Open the one-time pairing link in your browser, then use
`https://nixos-desktop.tailea9b59.ts.net/` from a device on your tailnet.
Pairing links expire after five minutes; browser sessions last 30 days. The
public URL uses implicit HTTPS port 443; port 49374 is only the loopback proxy
target. Keep Tailscale Funnel disabled for this service; Serve is tailnet-only.

Check the URL from another device and again after a reboot. If the web UI is
unreachable, check `systemctl --user status opencode-web` and
`tailscale serve status` on the desktop. An OpenCode TUI using `--standalone`
has its own server and is not the shared web service.
