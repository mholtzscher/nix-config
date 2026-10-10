# Platform Guidelines

Rules for platform-specific and host-specific config.

## Platform vs Host

- Platform-specific: differs by OS; use platform guards or platform modules
- Host-specific: differs by machine; use `modules/*/hosts/<hostname>/`
- Some config is both: keep it in the host module and still guard by platform if needed

Examples:

- Platform-specific: Homebrew, macOS defaults, systemd services, Linux kernel config
- Host-specific: work-only packages, personal-only apps, desktop-only UI modules

## Where Things Go

- macOS system config: `modules/darwin/`
- Homebrew config: `modules/darwin/homebrew/`
- NixOS system config: `modules/nixos/`
- Shared user config: `modules/home-manager/`
- Machine-specific overrides: `modules/*/hosts/<hostname>/`

## Preferred Platform Checks

Use injected module args instead of ad hoc platform detection when possible.

```nix
{ lib, isDarwin, isLinux, ... }:
{
  config = lib.mkIf isDarwin {
    programs.aerospace.enable = true;
  };
}
```

## Patterns

Conditional files:

```nix
home.file = {
  ".shared".text = "ok";
} // lib.optionalAttrs isDarwin {
  ".darwin-only".text = "ok";
};
```

Conditional programs or options:

```nix
config = lib.mkIf isDarwin {
  programs.aerospace.enable = true;
};
```

Conditional activation:

```nix
activation = lib.mkIf isDarwin {
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
- Keep apply commands out of agent workflows; validate with `nix flake check`
