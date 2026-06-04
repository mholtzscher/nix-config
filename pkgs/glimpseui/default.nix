{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs,
  makeWrapper,
  swift ? null,
  chromium ? null,
  xdg-utils ? null,
  xdotool ? null,
  xprop ? null,
  python3 ? null,
  socat ? null,
}:

stdenv.mkDerivation rec {
  pname = "glimpseui";
  version = "0.8.1";

  src = fetchFromGitHub {
    owner = "HazAT";
    repo = "glimpse";
    rev = "v${version}";
    hash = "sha256-iiOLxg8UnsKPwqNV+zCLFoQZ78pypMr3WkesSf3nkc8=";
  };

  nativeBuildInputs = [
    makeWrapper
    nodejs
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [ swift ];

  postPatch = lib.optionalString stdenv.hostPlatform.isLinux ''
    substituteInPlace src/chromium-backend.mjs \
      --replace-fail "const candidates = [" "const candidates = [ '${chromium}/bin/chromium',"
  '';

  buildPhase = lib.optionalString stdenv.hostPlatform.isDarwin ''
    runHook preBuild

    swiftc -O src/glimpse.swift -o src/glimpse

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    package_dir="$out/lib/node_modules/glimpseui"
    mkdir -p "$package_dir" "$out/bin"
    cp -R package.json README.md CHANGELOG.md bin src skills examples "$package_dir"/

    makeWrapper ${nodejs}/bin/node "$out/bin/glimpseui" \
      --add-flags "$package_dir/bin/glimpse.mjs" \
      ${lib.optionalString stdenv.hostPlatform.isLinux "--prefix PATH : ${
        lib.makeBinPath [
          chromium
          xdg-utils
          xdotool
          xprop
          python3
          socat
        ]
      }"}

    runHook postInstall
  '';

  meta = {
    description = "Native micro-UI for scripts and agents";
    homepage = "https://github.com/HazAT/glimpse";
    license = lib.licenses.mit;
    mainProgram = "glimpseui";
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
