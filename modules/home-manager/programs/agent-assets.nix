{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    all
    concatLists
    filter
    genList
    hasPrefix
    hasSuffix
    listToAttrs
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    nameValuePair
    optionalAttrs
    removeSuffix
    replaceStrings
    splitString
    sublist
    types
    unique
    ;

  cfg = config.programs."agent-assets";

  supportedTargets = [
    "opencode"
    "pi"
  ];

  pathType = path: if builtins.pathExists path then builtins.readFileType path else null;

  isMarkdownBasename = name: builtins.match "^[^/]+\\.md$" name != null;

  isSlug = name: builtins.match "^[A-Za-z0-9][A-Za-z0-9._-]*$" name != null;

  isSafeSubpath =
    subpath:
    subpath != null
    && subpath != ""
    && !(hasPrefix "/" subpath)
    && all (segment: segment != "" && segment != "." && segment != "..") (splitString "/" subpath);

  normalizeRoot = root: if hasSuffix "/" root then removeSuffix "/" root else root;

  sourceType = types.submodule {
    options = {
      type = mkOption {
        type = types.enum [
          "path"
          "url-file"
          "url-archive"
        ];
        description = "How to resolve the asset source.";
      };

      path = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Local file or directory path for `type = \"path\"`.";
      };

      url = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Remote URL for `url-file` or `url-archive` sources.";
      };

      hash = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Pinned hash for remote sources.";
      };

      subpath = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path inside a fetched archive for `url-archive` sources.";
      };
    };
  };

  assetType = types.submodule {
    options = {
      targets = mkOption {
        type = types.listOf (types.enum supportedTargets);
        default = [ ];
        description = "Install targets for this asset.";
      };

      source = mkOption {
        type = sourceType;
        description = "Asset source definition.";
      };
    };
  };

  targetType =
    description: defaultRoot:
    types.submodule {
      options = {
        enable = mkEnableOption description;

        root = mkOption {
          type = types.str;
          default = defaultRoot;
          description = "Install root for ${description}.";
        };
      };
    };

  collectAssets =
    kind: assets:
    mapAttrsToList (name: asset: {
      inherit kind name asset;
      id = "${kind}.${name}";
    }) assets;

  allAssets = concatLists [
    (collectAssets "docs" cfg.docs)
    (collectAssets "agents" cfg.agents)
    (collectAssets "commands" cfg.commands)
    (collectAssets "skills" cfg.skills)
  ];

  activeTargetsFor = assetDef: filter (target: cfg.targets.${target}.enable) assetDef.asset.targets;

  targetSupportsKind =
    target: kind:
    if target == "opencode" then
      true
    else if target == "pi" then
      builtins.elem kind [
        "docs"
        "skills"
      ]
    else
      false;

  destinationFor =
    target: kind: name:
    let
      root = normalizeRoot cfg.targets.${target}.root;
    in
    if target == "opencode" then
      if kind == "docs" then
        "${root}/${name}"
      else if kind == "agents" then
        "${root}/agents/${name}.md"
      else if kind == "commands" then
        "${root}/commands/${name}.md"
      else
        "${root}/skills/${name}"
    else if target == "pi" then
      if kind == "docs" then "${root}/${name}" else "${root}/skills/${name}"
    else
      throw "Unsupported agent asset target: ${target}";

  validationErrorsFor =
    assetDef:
    let
      src = assetDef.asset.source;
      activeTargets = activeTargetsFor assetDef;
      sourceLabel = "programs.\"agent-assets\".${assetDef.id}.source";
      pathLabel = "${sourceLabel}.path";
      targetsLabel = "programs.\"agent-assets\".${assetDef.id}.targets";
      keyErrors =
        if assetDef.kind == "docs" then
          if isMarkdownBasename assetDef.name then
            [ ]
          else
            [
              "programs.\"agent-assets\".${assetDef.id} must use a basename ending in `.md`."
            ]
        else if isSlug assetDef.name then
          [ ]
        else
          [
            "programs.\"agent-assets\".${assetDef.id} must use a slash-free slug matching `[A-Za-z0-9][A-Za-z0-9._-]*`."
          ];
      targetErrors =
        (if assetDef.asset.targets == [ ] then [ "${targetsLabel} must not be empty." ] else [ ])
        ++ (
          if builtins.length assetDef.asset.targets == builtins.length (unique assetDef.asset.targets) then
            [ ]
          else
            [ "${targetsLabel} contains duplicate targets." ]
        )
        ++ concatLists (
          map (
            target:
            if targetSupportsKind target assetDef.kind then
              [ ]
            else
              [
                "programs.\"agent-assets\".${assetDef.id} cannot target `${target}` for kind `${assetDef.kind}`."
              ]
          ) activeTargets
        );
      sourceErrors =
        if src.type == "path" then
          (
            if src.path != null then
              [ ]
            else
              [ "${pathLabel} is required when `${sourceLabel}.type = \"path\"`." ]
          )
          ++ (
            if src.url == null && src.hash == null && src.subpath == null then
              [ ]
            else
              [ "${sourceLabel} may only set `path` when `type = \"path\"`." ]
          )
          ++ (
            if src.path == null || builtins.pathExists src.path then [ ] else [ "${pathLabel} does not exist." ]
          )
          ++ (
            if src.path == null then
              [ ]
            else
              let
                currentPathType = pathType src.path;
              in
              if currentPathType == "symlink" then
                [ "${pathLabel} must not be a symlink for `${assetDef.id}`." ]
              else if assetDef.kind == "skills" then
                if currentPathType == "directory" then
                  [ ]
                else
                  [ "${pathLabel} must point to a directory for `${assetDef.id}`." ]
              else if currentPathType == "regular" then
                [ ]
              else
                [ "${pathLabel} must point to a file for `${assetDef.id}`." ]
          )
        else if src.type == "url-file" then
          (if src.url != null then [ ] else [ "${sourceLabel}.url is required when `type = \"url-file\"`." ])
          ++ (
            if src.hash != null then [ ] else [ "${sourceLabel}.hash is required when `type = \"url-file\"`." ]
          )
          ++ (
            if src.path == null && src.subpath == null then
              [ ]
            else
              [ "${sourceLabel} may only set `url` and `hash` when `type = \"url-file\"`." ]
          )
          ++ (
            if assetDef.kind == "skills" then
              [
                "`${assetDef.id}` must use `url-archive` or `path`, not `url-file`, because skills install directories."
              ]
            else
              [ ]
          )
        else
          (
            if src.url != null then [ ] else [ "${sourceLabel}.url is required when `type = \"url-archive\"`." ]
          )
          ++ (
            if src.hash != null then
              [ ]
            else
              [ "${sourceLabel}.hash is required when `type = \"url-archive\"`." ]
          )
          ++ (
            if isSafeSubpath src.subpath then
              [ ]
            else
              [ "${sourceLabel}.subpath must be a safe relative path without empty, `.` , or `..` segments." ]
          )
          ++ (
            if src.path == null then
              [ ]
            else
              [ "${sourceLabel} may not set `path` when `type = \"url-archive\"`." ]
          );
    in
    keyErrors ++ targetErrors ++ sourceErrors;

  baseValidationErrors = concatLists (map validationErrorsFor allAssets);

  resolveSource =
    assetDef:
    let
      src = assetDef.asset.source;
      derivationName = "agent-asset-${replaceStrings [ "." "/" ] [ "-" "-" ] assetDef.id}";
    in
    if src.type == "path" then
      src.path
    else if src.type == "url-file" then
      pkgs.fetchurl {
        url = src.url;
        hash = src.hash;
      }
    else
      let
        archive = pkgs.fetchzip {
          url = src.url;
          hash = src.hash;
          stripRoot = false;
        };
        selectedPath = "${archive}/${src.subpath}";
        expectDirectory = assetDef.kind == "skills";
        kindLabel = if expectDirectory then "directory" else "file";
      in
      pkgs.runCommand derivationName { } ''
        src=${lib.escapeShellArg selectedPath}

        if [ ! -e "$src" ]; then
          echo "Missing archive subpath '${src.subpath}' for ${assetDef.id}" >&2
          exit 1
        fi

        if [ ${if expectDirectory then "1" else "0"} -eq 1 ]; then
          if [ ! -d "$src" ]; then
            echo "Archive subpath '${src.subpath}' for ${assetDef.id} must be a ${kindLabel}" >&2
            exit 1
          fi

          mkdir -p "$out"
          cp -R "$src"/. "$out"/
        else
          if [ ! -f "$src" ]; then
            echo "Archive subpath '${src.subpath}' for ${assetDef.id} must be a ${kindLabel}" >&2
            exit 1
          fi

          cp "$src" "$out"
        fi
      '';

  generatedEntries = concatLists (
    map (
      assetDef:
      let
        activeTargets = activeTargetsFor assetDef;
      in
      if activeTargets == [ ] then
        [ ]
      else
        let
          resolvedSource = resolveSource assetDef;
        in
        map (target: {
          id = assetDef.id;
          dest = destinationFor target assetDef.kind assetDef.name;
          source = resolvedSource;
          recursive = assetDef.kind == "skills";
        }) activeTargets
    ) allAssets
  );

  collisionErrors =
    if baseValidationErrors != [ ] then
      [ ]
    else
      let
        entryCount = builtins.length generatedEntries;
        indices = genList (index: index) entryCount;
        messageFor =
          left: right:
          if left.dest == right.dest then
            "programs.\"agent-assets\": `${left.id}` and `${right.id}` both map to `${left.dest}`."
          else if hasPrefix "${left.dest}/" right.dest then
            "programs.\"agent-assets\": `${left.id}` maps to `${left.dest}`, which conflicts with child path `${right.dest}` from `${right.id}`."
          else if hasPrefix "${right.dest}/" left.dest then
            "programs.\"agent-assets\": `${right.id}` maps to `${right.dest}`, which conflicts with child path `${left.dest}` from `${left.id}`."
          else
            null;
      in
      concatLists (
        map (
          index:
          let
            left = builtins.elemAt generatedEntries index;
            rest = sublist (index + 1) (entryCount - index - 1) generatedEntries;
          in
          concatLists (
            map (
              right:
              let
                message = messageFor left right;
              in
              if message == null then [ ] else [ message ]
            ) rest
          )
        ) indices
      );

  validationErrors = baseValidationErrors ++ collisionErrors;

  generatedHomeFiles = listToAttrs (
    map (
      entry:
      nameValuePair entry.dest (
        {
          source = entry.source;
        }
        // optionalAttrs entry.recursive {
          recursive = true;
        }
      )
    ) generatedEntries
  );
in
{
  options.programs."agent-assets" = {
    enable = mkEnableOption "markdown-based agent asset installs";

    targets = {
      opencode = mkOption {
        type = targetType "OpenCode agent assets" "${config.xdg.configHome}/opencode";
        default = { };
      };

      pi = mkOption {
        type = targetType "Pi agent assets" "${config.home.homeDirectory}/.pi/agent";
        default = { };
      };
    };

    docs = mkOption {
      type = types.attrsOf assetType;
      default = { };
      description = "Top-level markdown docs keyed by destination basename.";
    };

    agents = mkOption {
      type = types.attrsOf assetType;
      default = { };
      description = "Markdown agent files keyed by agent name.";
    };

    commands = mkOption {
      type = types.attrsOf assetType;
      default = { };
      description = "Markdown command files keyed by command name.";
    };

    skills = mkOption {
      type = types.attrsOf assetType;
      default = { };
      description = "Skill directory trees keyed by skill name.";
    };
  };

  config = mkIf cfg.enable {
    assertions = map (message: {
      assertion = false;
      inherit message;
    }) validationErrors;

    home.file = mkIf (validationErrors == [ ]) generatedHomeFiles;
  };
}
