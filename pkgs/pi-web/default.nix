{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  python3,
}:

buildNpmPackage rec {
  pname = "pi-web";
  version = "1.202608.0";

  src = fetchFromGitHub {
    owner = "jmfederico";
    repo = "pi-web";
    rev = "v${version}";
    hash = "sha256-86OnGL+K6Y/EPRziQ1CMfX2kafqhOWb2auX+5yViatI=";
  };

  # PI WEB imports its Pi peer packages at runtime. Keep them as production
  # dependencies so buildNpmPackage's install phase does not prune them.
  postPatch = ''
    ${python3}/bin/python3 - <<'PY'
    import json
    from pathlib import Path

    pi_packages = (
        "@earendil-works/pi-agent-core",
        "@earendil-works/pi-ai",
        "@earendil-works/pi-coding-agent",
    )

    package_path = Path("package.json")
    package = json.loads(package_path.read_text())
    for name in pi_packages:
        package["dependencies"][name] = package["devDependencies"].pop(name)
    package_path.write_text(json.dumps(package, indent=2) + "\n")

    lock_path = Path("package-lock.json")
    lock = json.loads(lock_path.read_text())
    root_package = lock["packages"][""]
    for name in pi_packages:
        root_package["dependencies"][name] = root_package["devDependencies"].pop(name)

    # Upstream's lock file omits integrity fields for three nested dependencies.
    for name in pi_packages[:2]:
        nested = lock["packages"][
            f"node_modules/@earendil-works/pi-coding-agent/node_modules/{name}"
        ]
        top_level = lock["packages"][f"node_modules/{name}"]
        nested["integrity"] = top_level["integrity"]

    pi_tui = lock["packages"][
        "node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-tui"
    ]
    pi_tui["integrity"] = "sha512-IoYrb0rORjELmEpNtoCA/U8je3KopMkRAVJRdSzvXRvgb+Huo1gNh8Q5CSZvNOiYtDxJdj2tYZZHZ4B3+IN3hA=="

    lock_path.write_text(json.dumps(lock, indent=2) + "\n")
    PY
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-ViXnbQTUUZYJal3/5KBVFicroFyBsPQ5BnA5MxBEE1k=";

  nativeBuildInputs = [ python3 ];

  meta = {
    description = "Web UI for persistent Pi Coding Agent sessions";
    homepage = "https://pi-web.dev/";
    license = lib.licenses.mit;
    mainProgram = "pi-web";
    platforms = lib.platforms.linux;
  };
}
