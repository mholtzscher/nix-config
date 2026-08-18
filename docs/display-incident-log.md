# nixos-desktop display incident log

**Last updated:** 2026-08-18

**Host:** `nixos-desktop`

**Stack:** NVIDIA → DRM `DP-1` → Niri → Noctalia, through a KVM

Use this log to start future display triage. Add a dated entry after each incident,
even when the root cause remains unknown.

## Current recovery and diagnostics

- `Mod+Shift+O`: run `refresh-displays`, which asks Niri to power-cycle the
  monitors and falls back to `wlr-randr`. As of 2026-08-18, this binding is
  allowed while the session is locked.
- `Mod+Shift+I`: run `capture-display-debug`. This binding is not available
  while locked.
- Captures are stored under `~/.local/state/display-debug/`; `latest` points to
  the newest capture.
- The kernel currently receives:
  - `nvidia-drm.modeset=1`
  - `drm.edid_firmware=DP-1:edid/dp1.bin`
  - `video=DP-1:e`
- The configured mode is `5120x1440@120` on `DP-1`.

## Incident history

### 2026-04-29 — KVM return did not reconnect DP-1 (DMS era)

**Observed**

- Niri logged that `DP-1` disconnected and that no outputs remained.
- No later connector-reconnect event appeared before reboot.

**Finding**

- The EDID override preserves the monitor's modes but cannot make the NVIDIA
  driver consider a physically absent connector present.
- DMS could not recreate its surfaces because Niri never regained an output.

**Action at the time**

- Began work on an explicit display-reset helper.

**Pi session**

- `2026-04-29T18-49-38-417Z_019dda93-4770-73d8-a242-37786b5ab64e.jsonl`

### 2026-04-30 — Display-reset helper corrected (DMS era)

**Finding**

- The first helper attempted to write `detect` to DRM's `status` file. That
  file is read-only, so the reset did nothing.

**Resolution**

- Replaced it with `niri msg action power-off-monitors`, followed by
  `power-on-monitors`, with a `wlr-randr` fallback.
- Bound the helper to `Mod+Shift+O`.

**Pi session**

- `2026-04-30T17-17-35-749Z_019ddf65-5e84-77cd-ac86-50955f453459.jsonl`

### 2026-07-14 — Controlled KVM testing (DMS era)

**Observed**

- Successful returns followed this order: NVIDIA connector return, Niri
  recreates `DP-1`, then DMS recreates surfaces.
- Failed returns stopped before the first step: NVIDIA never reported the
  connector returning.
- Recovery succeeded with DMS both running and stopped. A 15-minute disconnect
  also recovered, so neither DMS nor disconnect duration alone caused the
  failure.

**Finding**

- The recurring boundary was NVIDIA/DRM DisplayPort hotplug or link retraining,
  not DMS rendering.
- The reset helper can retrain a link when Niri still owns an output, but may
  be ineffective when Niri sees zero outputs.

**Resolution/mitigation**

- Added `video=DP-1:e` to force the connector enabled.
- Added `capture-display-debug` and the persistent capture directory.

**Pi session**

- `2026-07-14T16-42-15-384Z_019f6181-f7d8-752f-9365-6eb30db50de3.jsonl`

### 2026-08-16 — Migrated from DMS to Noctalia

**Change**

- Removed DMS, Quickshell, and the Dank greeter.
- Made Noctalia the shell and Noctalia Greeter the greeter.
- Retained the EDID override, forced connector, reset helper, and capture tool.
- Updated captures to include Noctalia version, status, and journal entries.

**Pi sessions**

- `2026-08-16T17-40-17-306Z_01a00ba8-f51a-792d-9a10-9b46682f3e4e.jsonl`
- `2026-08-16T19-41-48-257Z_0b89f2ab-ff5b-4de0-9c46-ff7dd30d1542.jsonl`

### 2026-08-17 — Greeter rendered but monitor reported no signal

**Observed**

- The forced `DP-1` connector existed, EDID loaded, modesetting succeeded, and
  the Noctalia greeter rendered.
- The monitor nevertheless reported no signal.
- Blind login succeeded; `Mod+Shift+O` then restored the display.

**Finding**

- This was still consistent with a DisplayPort link-training failure rather
  than a missing compositor output.
- `video=DP-1:e` became a suspect: forcing presence may suppress the physical
  disconnect/reconnect transition needed to retrain the link.

**Status**

- Removing `video=DP-1:e` while retaining the EDID override was recommended as
  an experiment, but has not been applied.
- The same boot also showed a separate severe RCU/networking stall. Networking
  D-Bus calls timed out and reboot completion was delayed.

**Pi session**

- `2026-08-17T13-04-16-715Z_01a00fd2-9f4b-7ed8-9ef0-50a02173a26b.jsonl`

### 2026-08-18 — Display would not wake; probable whole-system hang

**Observed**

- The display did not return, blind unlock did not succeed, and the machine was
  force restarted at 07:48.
- The previous boot's last journal entry was at 05:00:26.
- Expected Noctalia activity and hourly systemd timers did not log afterward.
- There was no suspend sequence, orderly shutdown, NVIDIA Xid, DRM error, or
  `DP-1` disconnect near the end of the journal.
- The next boot recovered dirty filesystems and replaced unclean journal files.
- No reset-helper invocation or authentication attempt reached the journal.

**Finding**

- This differed from earlier display-only failures because system-wide periodic
  activity also stopped. The strongest conclusion is that the system stopped
  scheduling or journaling between 05:00 and 06:00, rather than only losing
  display output.
- A recurrence of the prior RCU/kernel stall is plausible but unproven because
  no final crash evidence survived.
- Repeated USB enumeration failures were for a separate endpoint on the shared
  KVM hub, not the Moonlander or virtual KVM keyboard, and ended many hours
  before this incident.

**Action**

- Changed `Mod+Shift+O` to `allow-when-locked=true`. Previously Niri suppressed
  this spawn binding while a session lock was active.
- Recorded this history for the next triage session.

## Next-incident checklist

1. Record the approximate failure and recovery/restart times and whether the
   monitor says **no signal** or shows a lit black image.
2. Try `Mod+Shift+O`; it should now work even while locked.
3. If the session is not locked, try `Mod+Shift+I` and check
   `~/.local/state/display-debug/latest/` after recovery.
4. From another machine, test ping/SSH before restarting. A reachable host
   strongly separates a display-link failure from a whole-system hang.
5. If SSH works, run `capture-display-debug` before resetting the display.
6. After a forced restart, preserve the previous boot before further testing:

   ```sh
   journalctl -b -1 -k --no-pager
   journalctl -b -1 --user -u niri.service -u noctalia.service --no-pager
   journalctl -b -1 --since '<time before failure>' --no-pager
   ```

7. Check specifically for:

   ```sh
   journalctl -b -1 --no-pager | rg -i \
     'nvrm|xid|drm|dp-1|rcu|stall|lockup|watchdog|suspend|resume|oom|I/O error'
   ```

8. Compare the result with the two known signatures:
   - **Display-link failure:** system remains reachable and logging; Niri either
     loses `DP-1` or still owns it but DPMS cycling restores the signal.
   - **Whole-system hang:** unrelated periodic logs also stop and SSH/input do
     not respond.

## Open experiments

- Test removing `video=DP-1:e` while keeping the EDID override. This may restore
  real hotplug transitions, but it may also reintroduce the earlier state where
  Niri sees zero outputs.
- If whole-system hangs recur, add crash telemetry that survives a hard lock,
  such as pstore or netconsole, and investigate the recent RCU stall separately.
