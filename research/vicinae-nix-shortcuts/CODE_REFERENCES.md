# Vicinae Shortcuts - Code References

## Key Source Files

### 1. Shortcuts Service (Main Implementation)

**File**: `vicinae/src/services/shortcut/shortcut-service.cpp`
**GitHub**: https://github.com/vicinaehq/vicinae/blob/main/vicinae/src/services/shortcut/shortcut-service.cpp

**Key Methods**:

```cpp
// Line ~6: Load all shortcuts from database
std::vector<std::shared_ptr<Shortcut>> ShortcutService::loadAll() {
    std::vector<std::shared_ptr<Shortcut>> shortcuts;
    QSqlQuery query = m_db.createQuery();

    query.prepare(R"(
        SELECT id, name, icon, url, app, open_count, created_at, updated_at, last_used_at
        FROM shortcut
    )");

    if (!query.exec()) {
        qCritical() << "Failed to execute loadAll query: " << query.lastError();
        return {};
    }

    while (query.next()) {
        Shortcut shortcut;
        shortcut.setId(query.value(0).toString());
        shortcut.setName(query.value(1).toString());
        shortcut.setIcon(query.value(2).toString());
        shortcut.parseLink(query.value(3).toString());
        shortcut.setApp(query.value(4).toString());
        shortcut.setOpenCount(query.value(5).toInt());
        shortcut.setCreatedAt(QDateTime::fromSecsSinceEpoch(query.value(6).toULongLong()));
        shortcut.setUpdatedAt(QDateTime::fromSecsSinceEpoch(query.value(7).toULongLong()));

        if (auto value = query.value(8); !value.isNull()) {
            shortcut.setLastOpenedAt(QDateTime::fromSecsSinceEpoch(value.toULongLong()));
        }

        shortcuts.emplace_back(std::make_shared<Shortcut>(shortcut));
    }

    return shortcuts;
}
```

```cpp
// Line ~165: Create new shortcut
bool ShortcutService::createShortcut(
    const QString &name, 
    const QString &icon, 
    const QString &url,
    const QString &app
) {
    Shortcut shortcut;

    {
        QSqlQuery query = m_db.createQuery();
        QString id = Crypto::UUID::v4();  // Generate UUID v4

        query.prepare(R"(
            INSERT INTO shortcut (id, name, icon, url, app) 
            VALUES (:id, :name, :icon, :url, :app)
            RETURNING id, name, icon, url, app, open_count, created_at, updated_at
        )");
        query.bindValue(":id", id);
        query.bindValue(":name", name);
        query.bindValue(":icon", icon);
        query.bindValue(":url", url);
        query.bindValue(":app", app);

        if (!query.exec()) {
            qWarning() << "Failed to save shortcut" << query.lastError();
            return false;
        }

        if (!query.next()) {
            qWarning() << "no next";
            return false;
        }

        shortcut.setId(query.value(0).toString());
        shortcut.setName(query.value(1).toString());
        shortcut.setIcon(query.value(2).toString());
        shortcut.parseLink(query.value(3).toString());
        shortcut.setApp(query.value(4).toString());
        shortcut.setOpenCount(query.value(5).toInt());
        shortcut.setCreatedAt(QDateTime::fromSecsSinceEpoch(query.value(6).toULongLong()));
        shortcut.setUpdatedAt(QDateTime::fromSecsSinceEpoch(query.value(7).toULongLong()));
        m_shortcuts.emplace_back(std::make_shared<Shortcut>(shortcut));
    }

    emit shortcutSaved(shortcut);
    return true;
}
```

### 2. Database Schema Definition

**File**: `vicinae/database/vicinae/migrations/001_init.sql`
**GitHub**: https://github.com/vicinaehq/vicinae/blob/main/vicinae/database/vicinae/migrations/001_init.sql

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

-- Tags support (planned, not used yet)
CREATE TABLE IF NOT EXISTS shortcut_tag (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    color INT NOT NULL
);

CREATE TABLE IF NOT EXISTS shortcut_tag_shortcut (
    shortcut_id TEXT NOT NULL,
    tag_id TEXT NOT NULL,
    PRIMARY KEY (shortcut_id, tag_id),
    FOREIGN KEY (shortcut_id) REFERENCES shortcut(id),
    FOREIGN KEY (tag_id) REFERENCES shortcut_tag(id)
);
```

### 3. Home-Manager Module

**File**: `nix/module.nix`
**GitHub**: https://github.com/vicinaehq/vicinae/blob/main/nix/module.nix

**Module Structure**:

```nix
{
  options.services.vicinae = {
    enable = lib.mkEnableOption "vicinae launcher daemon";
    
    package = lib.mkOption {
      type = lib.types.package;
      default = vicinaePkg;
    };
    
    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    
    useLayerShell = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    
    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
    };
    
    themes = lib.mkOption {
      type = /* TOML value type */;
      default = { };
      description = "Theme settings for ~/.local/share/vicinae/themes";
    };
    
    settings = lib.mkOption {
      type = /* JSON value type */;
      default = { };
      description = "Settings written as JSON to ~/.config/vicinae/vicinae.json";
    };
  };

  config = lib.mkIf cfg.enable {
    # Note: NO shortcuts configuration option exists
  };
}
```

**Key Observation**: No `shortcuts` option defined in the module.

### 4. Database Initialization

**File**: `vicinae/include/omni-database.hpp`
**GitHub**: https://github.com/vicinaehq/vicinae/blob/main/vicinae/include/omni-database.hpp

```cpp
#pragma once
#include "utils/migration-manager/migration-manager.hpp"

class OmniDatabase {
  QSqlDatabase _db;

public:
  QSqlDatabase &db() { return _db; }
  QSqlQuery createQuery() { return QSqlQuery(_db); }

  OmniDatabase(const std::filesystem::path &path) 
      : _db(QSqlDatabase::addDatabase("QSQLITE", "omni")) {
    
    std::filesystem::create_directories(path.parent_path());
    _db.setDatabaseName(path.c_str());

    if (!_db.open()) {
      qCritical() << "Could not open main omnicast SQLite database.";
      return;
    }

    auto query = createQuery();

    for (const auto &pragma : pragmas) {
      query.exec(pragma);
    }

    // This runs migrations from embedded resources
    MigrationManager manager(_db, "omnicast");
    manager.runMigrations();
  }
};
```

**Key Point**: Migrations are run from embedded resources (binary), not files.

### 5. Migration Manager

**File**: `vicinae/src/utils/migration-manager/migration-manager.cpp`
**GitHub**: https://github.com/vicinaehq/vicinae/blob/main/vicinae/src/utils/migration-manager/migration-manager.cpp

**Key Method**: Loads migrations from embedded resources

```cpp
std::vector<MigrationManager::Migration> MigrationManager::loadMigrations() {
  // Migrations loaded from embedded resource: :database/omnicast/migrations
  std::filesystem::path migrationDirPath =
      std::filesystem::path(":database") / 
      m_migrationNamespace.toStdString() / 
      "migrations";
  
  QDir migrationDir(migrationDirPath);
  std::vector<Migration> migrations;

  for (const auto &entry : migrationDir.entryList()) {
    std::filesystem::path migrationPath = migrationDirPath / entry.toStdString();
    auto result = loadMigrationFile(migrationPath);

    if (result) { migrations.emplace_back(*result); }
  }

  std::ranges::sort(migrations, [](auto &&a, auto &&b) { 
    return a.version < b.version; 
  });

  return migrations;
}
```

**Why This Matters**: Migrations cannot be customized or extended - they're compiled into the binary.

### 6. Service Registry

**File**: `vicinae/src/service-registry.cpp`
**GitHub**: https://github.com/vicinaehq/vicinae/blob/main/vicinae/src/service-registry.cpp

ShortcutService is created as part of application startup:

```cpp
#include "services/shortcut/shortcut-service.hpp"
#include "omni-database.hpp"

class ServiceRegistry : public QObject {
  // ...
  std::unique_ptr<OmniDatabase> m_omniDb;
  // ShortcutService is created with OmniDatabase reference
};
```

---

## Architecture Overview

### Data Flow

```
Application Start
    ↓
ServiceRegistry created
    ↓
OmniDatabase initialized
    ↓
MigrationManager.runMigrations()
    ↓
ShortcutService created
    ↓
ShortcutService::loadAll() executed
    ↓
All shortcuts loaded into memory
    ↓
UI displays shortcuts
```

### No Import Path

```
Input: JSON/TOML/CSV files
    ↓
??? (No conversion step exists)
    ↓
Cannot reach: SQLite database
```

---

## Why Import Doesn't Exist

Looking at the code:

1. **UUID Generation**: Only happens in `createShortcut()`, inside the service
2. **Database Access**: Encapsulated in `ShortcutService` and `OmniDatabase`
3. **CLI Interface**: No command-line API for shortcuts
4. **Serialization**: Shortcuts have no JSON/TOML serialization methods
5. **Module Design**: Home-manager module doesn't have shortcuts option

There is literally no code path to import shortcuts from a file.

---

## Relevant Type Definitions

**Shortcut Header**: `vicinae/src/services/shortcut/shortcut.hpp`

```cpp
class Shortcut {
  QString m_id;              // UUID v4
  QString m_name;            // Display name
  QString m_icon;            // Icon ref
  QString m_url;             // Link
  QString m_app;             // Associated app
  int m_openCount;           // Usage count
  QDateTime m_createdAt;     // Creation time
  QDateTime m_updatedAt;     // Last modified
  QDateTime m_lastOpenedAt;  // Last opened
};
```

**ShortcutService Header**: `vicinae/src/services/shortcut/shortcut-service.hpp`

```cpp
class ShortcutService : public QObject {
  Q_OBJECT

  OmniDatabase &m_db;
  std::vector<std::shared_ptr<Shortcut>> m_shortcuts;
  std::vector<std::shared_ptr<Shortcut>> loadAll();

public:
  std::vector<std::shared_ptr<Shortcut>> shortcuts() const;
  bool createShortcut(const QString &name, const QString &icon, 
                      const QString &url, const QString &app);
  bool updateShortcut(const QString &id, const QString &name, 
                      const QString &icon, const QString &url, 
                      const QString &app);
  bool removeShortcut(const QString &id);
  Shortcut *findById(const QString &id);
  bool registerVisit(const QString &id);

signals:
  void shortcutSaved(const Shortcut &shortcut) const;
  void shortcutUpdated(const QString &id) const;
  void shortcutRemoved(const QString &id) const;
  void shortcutVisited(const QString &id) const;
};
```

---

## Conclusion

The codebase confirms:

1. ✅ Shortcuts stored in SQLite database
2. ❌ No import/export mechanism
3. ❌ No file-based configuration
4. ❌ No command-line interface for shortcuts
5. ❌ Home-manager module doesn't support shortcuts
6. 🔒 Migrations compiled into binary, not extensible

**To support declarative shortcuts would require major changes to Vicinae architecture.**

---

**Document Version**: 1.0
**Last Updated**: November 2025
**Vicinae Repo**: https://github.com/vicinaehq/vicinae
