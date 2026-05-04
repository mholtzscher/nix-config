{
  stdenvNoCC,
  fetchurl,
  lib,
}:

let
  version = "0.6.0";

  assets = {
    aarch64-darwin = {
      name = "ghui-darwin-arm64.tar.gz";
      hash = "sha256-7vb/+WjXaDPWUNgRC6F2cz3vaz6EciFmswCkWwclkHg=";
    };
    x86_64-darwin = {
      name = "ghui-darwin-x64.tar.gz";
      hash = "sha256-IUL1ElQV7qyqRDjSpBaxLUxOhzOGxBAoCfMYXWzx3Iw=";
    };
    aarch64-linux = {
      name = "ghui-linux-arm64.tar.gz";
      hash = "sha256-XtxVh/+vOQXeR0XGY/YtId8CG1NlZX0Y6+3OWIgbVO8=";
    };
    x86_64-linux = {
      name = "ghui-linux-x64.tar.gz";
      hash = "sha256-sIUb5j0WAzu2nWwMASKr5x3Ng5i4PxAZ0XCn3GChYnk=";
    };
  };

  asset =
    assets.${stdenvNoCC.hostPlatform.system}
      or (throw "ghui is not packaged for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "ghui";
  inherit version;

  src = fetchurl {
    url = "https://github.com/kitlangton/ghui/releases/download/v${version}/${asset.name}";
    inherit (asset) hash;
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    install -Dm755 ghui "$out/bin/ghui"

    runHook postInstall
  '';

  meta = {
    description = "A GitHub TUI";
    homepage = "https://github.com/kitlangton/ghui";
    license = lib.licenses.mit;
    mainProgram = "ghui";
    platforms = builtins.attrNames assets;
  };
}
