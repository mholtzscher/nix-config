# Quick Fix: Duplicate Home-Manager Configuration

## The Issue (TL;DR)

Two systems are importing the same programs twice:
- `nixos-desktop-dendritic.nix` ❌
- `wanda-dendritic.nix` ❌

This causes Nix to fail with: `error: attribute 'bat' already defined at location1, now at location2`

## The Fix (Copy & Paste)

### Fix 1: nixos-desktop-dendritic.nix

**Location**: `/Users/michael/.config/nix-config/hosts/nixos-desktop-dendritic.nix`

**Before** (lines 62-67):
```nix
    }

    # Legacy bridge - brings in all the NixOS system config
    ../hosts/nixos/nixos-desktop
  ];
}
```

**After** (lines 62-64):
```nix
    }
  ];
}
```

**Action**: Delete lines 64-65 (the comment and the bridge import)

---

### Fix 2: wanda-dendritic.nix

**Location**: `/Users/michael/.config/nix-config/hosts/wanda-dendritic.nix`

**Before** (lines 32-37):
```nix
    inputs.catppuccin.homeModules.catppuccin

    # Legacy bridge
    ../hosts/ubuntu/wanda.nix
  ];
}
```

**After** (lines 32-35):
```nix
    inputs.catppuccin.homeModules.catppuccin
  ];
}
```

**Action**: Delete lines 34-35 (the comment and the bridge import)

---

## Verification

After making the changes, run:

```bash
# Check syntax
nix flake check

# Build nixos-desktop
nix build .#nixos-desktop

# Build wanda home-manager
nix build .#wanda
```

All three should succeed without errors!

---

## What This Fixes

| System | Before | After |
|--------|--------|-------|
| personal-mac | ✅ Working | ✅ Working |
| work-mac | ✅ Working | ✅ Working |
| nixos-desktop | ❌ BROKEN | ✅ FIXED |
| wanda | ❌ BROKEN | ✅ FIXED |

---

## Why This Works

**Before**: 
```
nixos-desktop-dendritic.nix
├─ imports bat, eza, fzf, git, ripgrep, zoxide (dendritic)
└─ imports ../hosts/nixos/nixos-desktop
   └─ ALSO imports bat, eza, fzf, git, ripgrep, zoxide (legacy)
   └─ ERROR: attribute 'bat' already defined!
```

**After**:
```
nixos-desktop-dendritic.nix
├─ imports bat, eza, fzf, git, ripgrep, zoxide (dendritic)
└─ No legacy bridge
   └─ No duplicate imports ✓
```

---

## Don't Delete These (Yet)

These files still exist but are unused now - safe to leave them:
- `hosts/darwin/personal-mac.nix` (unused, -dendritic version is active)
- `hosts/darwin/work-mac.nix` (unused, -dendritic version is active)
- `hosts/nixos/nixos-desktop/default.nix` (can be deleted later)
- `hosts/ubuntu/wanda.nix` (can be deleted later)
- `modules-legacy/` (keep for reference, nothing imported anymore)

Can delete these anytime if you want to clean up, but they're harmless if left.

---

## Duplicate Programs (Now Fixed)

These were defined in both dendritic AND legacy modules:
- bat
- eza
- fzf
- git
- ripgrep
- zoxide

After the fix, only the dendritic versions are imported.

---

## Need More Details?

See the other research documents:
- `SUMMARY.md` - Executive summary
- `findings.md` - Detailed root cause
- `architecture.md` - Visual import trees
- `debug-report.md` - Investigation process
- `README.md` - Overview and guide
