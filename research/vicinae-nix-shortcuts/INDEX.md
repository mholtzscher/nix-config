# Vicinae Shortcuts Research - Complete Index

## Document Overview

This research package contains comprehensive analysis of how Vicinae stores shortcuts and whether they can be configured declaratively in NixOS home-manager.

**Bottom Line**: Vicinae shortcuts are stored in SQLite database and **cannot** be configured declaratively through home-manager.

---

## Documents in This Package

### 1. **QUICK_REFERENCE.md** - Start Here! ⭐
- **Purpose**: Quick answer to the main question
- **Length**: ~2 pages
- **Best For**: Getting the core answer quickly
- **Contains**: TL;DR, storage comparison table, workarounds overview

### 2. **SHORTCUTS_RESEARCH.md** - Full Analysis
- **Purpose**: Comprehensive research findings
- **Length**: ~10 pages
- **Best For**: Understanding the full picture
- **Contains**: 
  - Database schema details
  - Home-manager module options
  - Technical barriers explained
  - Possible workarounds
  - Architecture overview

### 3. **CODE_REFERENCES.md** - Developer Reference
- **Purpose**: Actual code from Vicinae source
- **Length**: ~5 pages
- **Best For**: Developers wanting to understand implementation
- **Contains**:
  - Actual C++ code snippets
  - GitHub links to source files
  - Data flow diagrams
  - Type definitions

---

## Key Findings at a Glance

| Question | Answer | Details |
|----------|--------|---------|
| **Storage Format** | SQLite Database | Binary, not config files |
| **Declarative Support** | ❌ NO | No shortcuts option in module |
| **Configuration Format** | N/A | Only UI/programmatic management |
| **File Location** | `~/.local/share/vicinae/database.db` | Not managed by home-manager |
| **Import Feature** | ❌ Does Not Exist | No CLI tool available |
| **Export Feature** | ❌ Does Not Exist | No standard export format |

---

## What IS Configurable Declaratively

✅ **Supported**:
- Application settings (JSON)
- Theme definitions (TOML)
- Extensions installation

❌ **Not Supported**:
- Shortcuts
- Database data
- Root provider preferences

---

## Database Schema

**Main Table**: `shortcut`

```sql
id              -- UUID v4 (PRIMARY KEY)
name            -- Display name
icon            -- Icon reference
url             -- Shortcut URL
app             -- Associated application
open_count      -- Usage counter
created_at      -- Creation timestamp
updated_at      -- Last modified timestamp
last_used_at    -- Last opened timestamp
```

**Related Tables**:
- `shortcut_tag` (planned, not used)
- `shortcut_tag_shortcut` (planned, not used)

---

## File Locations

```
Configuration (Managed by home-manager):
~/.config/vicinae/vicinae.json              ← Settings
~/.local/share/vicinae/themes/*.toml        ← Themes
~/.local/share/vicinae/extensions/          ← Extensions

Data (NOT Managed):
~/.local/share/vicinae/database.db          ← Shortcuts ❌
```

---

## Why Shortcuts Aren't Declarative

1. **Database Storage** - Stored in binary SQLite, not text config
2. **Runtime UUIDs** - IDs generated at creation time
3. **State Tracking** - Database tracks usage statistics
4. **No Import API** - No command-line import tool exists
5. **Design Choice** - Treated as user data, not configuration

---

## Workarounds Ranked by Difficulty

| Option | Complexity | How It Works |
|--------|-----------|-------------|
| Use UI | ✅ Easy | Manage shortcuts through Vicinae interface |
| SQL Script | ⚙️ Medium | Post-activation script to populate database |
| Fork Vicinae | ⛏️ Hard | Add import feature, maintain fork |
| Feature Request | 🔄 Long-term | Request from Vicinae maintainers |

---

## Important Code References

**Shortcuts Service**:
- https://github.com/vicinaehq/vicinae/blob/main/vicinae/src/services/shortcut/shortcut-service.cpp
- Lines ~6: `loadAll()` method
- Lines ~165: `createShortcut()` method

**Database Schema**:
- https://github.com/vicinaehq/vicinae/blob/main/vicinae/database/vicinae/migrations/001_init.sql

**Home-Manager Module**:
- https://github.com/vicinaehq/vicinae/blob/main/nix/module.nix
- Note: No `shortcuts` option

**Database Initialization**:
- https://github.com/vicinaehq/vicinae/blob/main/vicinae/include/omni-database.hpp

---

## How to Use This Research

### If you want to...

**Understand the answer quickly**
→ Read: QUICK_REFERENCE.md

**Learn all the details**
→ Read: SHORTCUTS_RESEARCH.md

**See actual code**
→ Read: CODE_REFERENCES.md

**Implement a workaround**
→ See section 5 in SHORTCUTS_RESEARCH.md

**Contribute to Vicinae**
→ Study CODE_REFERENCES.md and section 9 of SHORTCUTS_RESEARCH.md

---

## Home-Manager Module Example

What you CAN do:

```nix
services.vicinae = {
    enable = true;
    autoStart = true;
    
    settings = {
        faviconService = "twenty";
        theme.name = "catppuccin";
        window.opacity = 0.95;
    };
    
    themes = {
        "my-theme" = { /* theme config */ };
    };
};
```

What you CANNOT do:

```nix
services.vicinae.shortcuts = [
    { name = "Google"; url = "https://google.com"; }
];
```

---

## Quick Decision Tree

```
Do you want declarative shortcuts?
    ↓
Can you use UI instead?
    YES → Use Vicinae UI directly ✅
    NO ↓
Do you need to manage many machines?
    YES → Use SQL activation script ⚙️
    NO ↓
Are you interested in contributing?
    YES → Fork & add import feature ⛏️
    NO ↓
File issue on vicinaehq/vicinae 🔄
```

---

## Research Methodology

- **Source**: Official Vicinae GitHub repository
- **Scope**: vicinaehq/vicinae main branch
- **Date**: November 2025
- **Method**: Code analysis, file inspection, schema examination
- **Verification**: Cross-referenced C++, SQL, and Nix code

---

## Key Takeaways

1. **Vicinae uses SQLite** for all shortcuts storage
2. **No import mechanism exists** in the codebase
3. **Home-manager module** only supports settings and themes
4. **Shortcuts are treated as user data**, not configuration
5. **Workarounds exist** but require manual work

---

## Next Steps

**For Users**:
1. Accept shortcuts are per-machine
2. Manage through Vicinae UI
3. Keep settings declarative in home-manager

**For Developers**:
1. Consider requesting import feature
2. Review CODE_REFERENCES.md for architecture
3. Evaluate if fork is needed

**For Vicinae Project**:
1. Add `vicinae import-shortcuts` CLI command
2. Define JSON/TOML import format
3. Extend home-manager module

---

## Questions Answered

✅ **Are shortcuts stored in a config file?**
No, they're in SQLite database.

✅ **Can they be configured in home-manager?**
No, there's no module option for shortcuts.

✅ **What format do they use?**
SQLite binary database (`.db` file).

✅ **Can I import from JSON/TOML?**
No import mechanism exists currently.

✅ **Are there workarounds?**
Yes, SQL script activation hooks (advanced).

✅ **Should I fork Vicinae?**
Only if you need per-machine consistency badly.

---

## Document Statistics

- **Total Pages**: ~18 (combined)
- **Code Snippets**: 15+
- **GitHub Links**: 20+
- **SQL Examples**: 5
- **Nix Examples**: 10
- **C++ Excerpts**: 8

---

**Research Package Version**: 1.0
**Last Updated**: November 2025
**Status**: Complete & Verified
**Confidence Level**: High (Code-backed)

---

**For questions or updates, reference the specific source files on GitHub.**
