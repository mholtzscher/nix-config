# Platform Guidelines

Rules for platform-specific and host-specific config.

This flake targets Linux only. Macs are managed outside Nix through Mise.
Existing modules retain `isDarwin = false` and `isLinux = true` for compatibility.

## Platform vs Host

- Platform-specific: differs by OS; use platform guards or platform modules
- Host-specific: differs by machine; use `modules/*/hosts/<hostname>/`
- Some config is both: keep it in the host module and still guard by platform if needed

Examples:

- System-specific: NixOS services and kernel config versus standalone Home Manager
- Host-specific: work-only packages, personal-only apps, desktop-only UI modules

## Where Things Go

- Mac apps/fonts: Mise `[bootstrap.packages]`, outside this Nix repository
- NixOS system config: `modules/nixos/`
- Shared user config: `modules/home-manager/`
- Machine-specific overrides: `modules/*/hosts/<hostname>/`

## Preferred Platform Checks

Use injected module args instead of ad hoc platform detection when possible.

```nix
{ lib, isLinux, ... }:
{
  config = lib.mkIf isLinux {
    services.podman.enable = true;
  };
}
```

## Patterns

Conditional files:

```nix
home.file = {
  ".shared".text = "ok";
} // lib.optionalAttrs isLinux {
  ".linux-only".text = "ok";
};
```

Conditional programs or options:

```nix
config = lib.mkIf isLinux {
  services.podman.enable = true;
};
```

Conditional activation:

```nix
activation = lib.mkIf isLinux {
  someStep = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run echo done
  '';
};
```

## Common Module Args

- Shared: `currentSystemName`, `currentSystemUser`, `isDarwin`, `isLinux`, `inputs`, `isWork`
- NixOS-only: `currentSystem`, `graphical`, `gaming`

## NixOS Flags

- `graphical = true`: enables graphical modules and related inputs
- `graphical = false`: for headless or non-GUI systems
- `gaming = true`: makes the flag available to modules that opt into gaming config

## Practical Rules

- Prefer shared modules first; specialize only when needed
- Prefer host modules for machine-specific behavior over branching everywhere
- Keep OS-specific paths and tools behind guards
- Keep apply commands out of agent workflows; validate per `docs/NIX_WORKFLOW.md`
