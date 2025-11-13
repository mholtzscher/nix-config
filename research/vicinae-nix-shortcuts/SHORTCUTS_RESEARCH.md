# Vicinae Shortcuts Configuration Research

## Overview

This document details the findings from researching how Vicinae stores and manages shortcuts, and whether they can be configured declaratively through NixOS home-manager.

## Key Findings Summary

✅ **Shortcuts Storage Format**: SQLite database (binary)
❌ **Declarative Shortcuts Support**: NOT supported in home-manager module
❌ **Configuration File Format**: No JSON/TOML shortcuts config - only UI management

---

## 1. Shortcuts Storage Details

### Database Location
- **Path**: `~/.local/share/vicinae/database.db` (SQLite)
- **Type**: SQLite3 database
- **Access Method**: Programmatic via C++ Qt code

### Database Schema

**Shortcuts Table**:
```sql
CREATE TABLE IF NOT EXISTS shortcut (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    icon TEXT NOT NULL,
    url TEXT NOT NULL,
    app TEXT NOT NULL,
    open_count INTEGER DEFAULT 0,
    created_at INTEGER DEFAULT (unixepoch()),
    updated_at INTEGER DEFAULT (unixepoch()),
    last_used_at INTEGER
);
```

**Column Details**:
- `id`: UUID v4 string (generated programmatically)
- `name`: Display name of the shortcut
- `icon`: Icon reference string
- `url`: The actual link/URL the shortcut points to
- `app`: Associated application (optional)
- `open_count`: Usage tracking - number of times opened
- `created_at`, `updated_at`, `last_used_at`: Unix epoch timestamps

### File Locations

**File Structure**:
```
~/.local/share/vicinae/
├── database.db                    # Main database (SQLite)
├── extensions/
└── themes/

~/.config/vicinae/
├── vicinae.json                   # Main settings (JSON)
└── themes/                        # Theme files (TOML)
```

### Migration System

**Location**: Embedded in binary as resources
- **Resource Namespace**: `database/omnicast`
- **Files**: Compiled into binary at build time
- **Path in Source**: `vicinae/database/vicinae/migrations/`

**Migration Files**:
1. `001_init.sql` - Creates all base tables including `shortcut`
2. `002_add_recent_files.sql` - Recent files support
3. `003_add_oauth_token_store.sql` - OAuth integration

---

## 2. Shortcut Management

### How Shortcuts Are Created

**C++ Service Class**: `ShortcutService`
- **File**: `vicinae/src/services/shortcut/shortcut-service.cpp`
- **Method**: `createShortcut()`

Key characteristics:
- Generates UUID v4 for each shortcut
- Inserts directly into SQLite database
- Called only from UI or programmatic API
- No file import mechanism exists

### Loading Shortcuts

On application startup:
1. OmniDatabase opens `~/.local/share/vicinae/database.db`
2. MigrationManager runs all migrations
3. ShortcutService::loadAll() queries all shortcuts from DB
4. Shortcuts loaded into memory vector

---

## 3. Home-Manager Integration

### Current Module Status

**File**: `nix/module.nix` in Vicinae repo
- **GitHub**: https://github.com/vicinaehq/vicinae/blob/main/nix/module.nix
- **Status**: Only supports settings and themes, NOT shortcuts

### Available Options

```
services.vicinae.enable               - Enable Vicinae daemon
services.vicinae.autoStart            - Auto-start with session
services.vicinae.useLayerShell        - Use layer shell
services.vicinae.extensions           - Extensions packages
services.vicinae.themes               - Theme definitions (TOML)
services.vicinae.settings             - Application settings (JSON)
```

### Supported vs Unsupported

**SUPPORTED - Declarative**:
- Application settings (opacity, font size, theme, etc.)
- Theme files (TOML format)
- Extensions packages

**UNSUPPORTED - No Config**:
- Shortcuts definition
- Root provider preferences
- Database initialization with data

### Configuration Files Managed

**Managed by Module**:
- ✅ `~/.config/vicinae/vicinae.json` - Settings
- ✅ `~/.local/share/vicinae/themes/*.toml` - Themes
- ✅ `~/.local/share/vicinae/extensions/` - Extensions

**NOT Managed**:
- ❌ `~/.local/share/vicinae/database.db` - Shortcuts and data
- ❌ Database initialization with seed data

---

## 4. Why Declarative Shortcuts Aren't Supported

### Technical Barriers

1. **Database-First Storage**:
   - All shortcuts stored in SQLite binary database
   - No text-based config file exists for shortcuts
   - No file import/export mechanism in codebase

2. **UUID Generation at Runtime**:
   - Each shortcut requires unique UUID v4
   - Generated during creation, not pre-assigned
   - Cannot be predictably defined in declarative config

3. **Runtime State Tracking**:
   - Database tracks `open_count`, `last_used_at`
   - These values change during execution
   - Declarative config would conflict with runtime updates

4. **Embedded Migrations**:
   - Database schema compiled into binary
   - No way to inject custom SQL at setup time
   - Migrations cannot be extended or customized

5. **No Import API**:
   - No command-line tool for importing shortcuts
   - No JSON/TOML import format exposed
   - Must use GUI or C++ programmatic API

### Design Philosophy

Vicinae intentionally separates:
- **Settings** (config files) - Declarative, user-controlled
- **Themes** (theme files) - Declarative, user-controlled
- **Shortcuts** (database data) - Runtime, user-generated

This aligns with how other apps treat bookmarks or history - as user data, not system configuration.

---

## 5. Possible Workarounds

### Workaround 1: Database Seeding with SQL Script

Create activation script to populate database:

```bash
# After database exists (created by Vicinae on first run)
sqlite3 ~/.local/share/vicinae/database.db <<SQL
INSERT INTO shortcut (id, name, icon, url, app) 
VALUES (
  '550e8400-e29b-41d4-a716-446655440000',
  'Search Google',
  'search.svg',
  'https://google.com',
  'firefox'
);
SQL
```

**Limitations**:
- Database must exist first (app creates on first run)
- Must manually manage UUIDs
- Poor error handling
- Not portable across systems

### Workaround 2: Post-Activation Hook

```bash
home.activation.vicinaeShortcuts = config.lib.dag.entryAfter 
  ["writeBoundary"] ''
  if [ -f "$HOME/.local/share/vicinae/database.db" ]; then
    ${pkgs.sqlite}/bin/sqlite3 \
      "$HOME/.local/share/vicinae/database.db" < ${./vicinae-shortcuts.sql}
  fi
'';
```

### Workaround 3: Fork Vicinae with Import Feature

Would require:
1. Adding `vicinae import-shortcuts <file>` CLI command
2. Implementing JSON/TOML shortcut format
3. UUID generation during import
4. Maintaining fork long-term

---

## 6. Data Flow

### Current (Settings/Themes)

```
Nix Configuration
    ↓
home-manager module
    ↓
xdg.configFile/xdg.dataFile
    ↓
~/.config/vicinae/vicinae.json
~/.local/share/vicinae/themes/*.toml
    ↓
Vicinae reads on startup
```

### Missing (Shortcuts)

```
Desired Nix Configuration
    ↓
home-manager module (NO SUPPORT)
    ↓
???
    ↓
~/.local/share/vicinae/database.db
    ↓
Vicinae loads from database
```

---

## 7. Current Usage Example

What IS possible declaratively:

```nix
services.vicinae = {
    enable = true;
    autoStart = true;
    useLayerShell = true;
    
    settings = {
        faviconService = "twenty";
        font.size = 11;
        theme.name = "catppuccin";
        window = {
            opacity = 0.95;
            rounding = 10;
            csd = true;
        };
        rootSearch.searchFiles = false;
    };
    
    themes = {
        catppuccin-mocha = {
            version = "1.0.0";
            appearance = "dark";
            palette = {
                background = "#1e1e2e";
                foreground = "#cdd6f4";
            };
        };
    };
};
```

What is NOT possible:
```nix
# This option does not exist in the module
services.vicinae.shortcuts = [
    {
        name = "Google Search";
        url = "https://google.com";
        icon = "search.svg";
    }
];
```

---

## 8. References

### GitHub Files

**Shortcuts Service**:
- https://github.com/vicinaehq/vicinae/blob/main/vicinae/src/services/shortcut/shortcut-service.cpp
- https://github.com/vicinaehq/vicinae/blob/main/vicinae/src/services/shortcut/shortcut-service.hpp

**Database & Migrations**:
- https://github.com/vicinaehq/vicinae/blob/main/vicinae/include/omni-database.hpp
- https://github.com/vicinaehq/vicinae/blob/main/vicinae/database/vicinae/migrations/001_init.sql
- https://github.com/vicinaehq/vicinae/blob/main/vicinae/src/utils/migration-manager/migration-manager.cpp

**Home-Manager Module**:
- https://github.com/vicinaehq/vicinae/blob/main/nix/module.nix

### Key Code Snippets Location

**Shortcut Creation** (shortcut-service.cpp, line ~165):
- Generates UUID v4
- Inserts into database
- Returns created shortcut object

**Shortcut Loading** (shortcut-service.cpp, line ~6):
- Queries all shortcuts from DB table
- Loads into memory vector
- Called during service initialization

**Schema Definition** (001_init.sql):
- Defines `shortcut` table with all fields
- Also defines `shortcut_tag` (not used yet)

---

## 9. Recommendations

### For Nix Users

**Current Best Practice**:
1. Use Vicinae UI to manage shortcuts
2. Manage settings declaratively in home-manager
3. Backup database periodically
4. Accept per-machine shortcut management

**If You Need Portability**:
1. Export shortcuts manually from Vicinae UI (if supported)
2. Use activation script to seed database on new machines
3. Maintain external shortcut list (e.g., JSON file)

### For Vicinae Project

**Feature Requests** (in priority order):
1. Add shortcut export to JSON/TOML format
2. Add `vicinae import-shortcuts <file>` CLI command
3. Support initial seed database from config file
4. Document database schema for advanced users
5. Consider separating "default shortcuts" from user data

---

## 10. Conclusion

### Direct Answer: NO

**Vicinae shortcuts CANNOT be configured declaratively in home-manager.**

### Why

- Shortcuts are stored in SQLite database, not config files
- No import mechanism exists
- Designed as runtime user data, not system configuration
- Module only supports settings and themes

### What Works Declaratively

- Application settings ✅
- Theme definitions ✅
- Extensions installation ✅

### What Doesn't

- Shortcuts ❌
- Database initialization ❌
- Per-user data seeding ❌

### Workarounds

1. Manual UI management (simplest)
2. Post-activation SQL script (semi-automated)
3. Fork with import feature (complex)
4. Request feature from Vicinae maintainers (long-term)

---

**Research Date**: November 2025
**Vicinae Version**: Latest main branch
**Information Sources**: GitHub repository (vicinaehq/vicinae)
**Status**: Confirmed as of latest commits
