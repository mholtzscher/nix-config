# Vicinae Shortcuts - Quick Reference

## TL;DR

**Can I configure Vicinae shortcuts declaratively in NixOS home-manager?**

**No.** ❌

---

## Storage Method

| Item | Storage | Format | Declarative? |
|------|---------|--------|--------------|
| Settings | `~/.config/vicinae/vicinae.json` | JSON | ✅ Yes |
| Themes | `~/.local/share/vicinae/themes/*.toml` | TOML | ✅ Yes |
| **Shortcuts** | **`~/.local/share/vicinae/database.db`** | **SQLite** | **❌ No** |

---

## Database Schema

**Table**: `shortcut`

```sql
id              TEXT PRIMARY KEY    -- UUID v4
name            TEXT NOT NULL       -- Display name
icon            TEXT NOT NULL       -- Icon path/ref
url             TEXT NOT NULL       -- The shortcut URL/link
app             TEXT NOT NULL       -- Associated app
open_count      INTEGER             -- Usage counter
created_at      INTEGER             -- Unix timestamp
updated_at      INTEGER             -- Unix timestamp
last_used_at    INTEGER             -- Unix timestamp
```

---

## Home-Manager Module Status

### What Works ✅

```nix
services.vicinae.settings = {
    faviconService = "twenty";
    font.size = 11;
    theme.name = "catppuccin";
    window.opacity = 0.95;
};

services.vicinae.themes = {
    "my-theme" = { /* TOML config */ };
};

services.vicinae.extensions = [ /* packages */ ];
```

### What Doesn't Work ❌

```nix
services.vicinae.shortcuts = [ /* NO SUCH OPTION */ ];
```

---

## Why?

1. **Database-only storage** - No config file for shortcuts
2. **Runtime generation** - UUIDs generated at creation time
3. **No import API** - Vicinae has no `import-shortcuts` command
4. **Design choice** - Shortcuts are user data, not config
5. **State tracking** - Database tracks usage (open_count, last_used_at)

---

## Workarounds

### Option 1: Use the UI ✅ Simplest
Manage shortcuts directly in Vicinae interface.

### Option 2: SQL Activation Script ⚙️ Semi-Automated
```bash
home.activation.seeds = lib.mkAfter ''
  sqlite3 ~/.local/share/vicinae/database.db < ${./seed.sql}
'';
```

### Option 3: Fork Vicinae ⛏️ Complex
Add import feature to Vicinae, maintain fork.

### Option 4: Request Feature 🔄 Best Long-term
File issue on vicinaehq/vicinae for import support.

---

## File Locations

```
~/.config/vicinae/vicinae.json              ← Settings (managed)
~/.local/share/vicinae/database.db          ← Shortcuts (NOT managed)
~/.local/share/vicinae/themes/*.toml        ← Themes (managed)
~/.local/share/vicinae/extensions/          ← Extensions (managed)
```

---

## Module Options

```
services.vicinae = {
    enable = true/false
    autoStart = true/false
    useLayerShell = true/false
    package = pkgs.vicinae
    extensions = [ /* packages */ ]
    themes = { /* TOML */ }
    settings = { /* JSON */ }
    # NOTE: NO shortcuts option
};
```

---

## GitHub References

- **Module**: https://github.com/vicinaehq/vicinae/blob/main/nix/module.nix
- **Shortcuts Service**: https://github.com/vicinaehq/vicinae/blob/main/vicinae/src/services/shortcut/shortcut-service.cpp
- **Database Schema**: https://github.com/vicinaehq/vicinae/blob/main/vicinae/database/vicinae/migrations/001_init.sql

---

## Related Tables in Database

```sql
-- Shortcuts (main)
shortcut

-- Tags for shortcuts (planned, not used yet)
shortcut_tag
shortcut_tag_shortcut

-- Root providers (plugin system)
root_provider
root_provider_item

-- Other data
recent_file
calculator_history
visited_emoji
storage_data_item
```

---

## Recommendation

**For most users**: Accept that shortcuts are managed through UI, keep settings declarative.

**For advanced users**: Use post-activation SQL script if you need consistent shortcuts across machines.

**For developers**: Consider contributing import feature to Vicinae project.
