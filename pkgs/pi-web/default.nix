{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  python3,
}:

buildNpmPackage rec {
  pname = "pi-web";
  version = "1.202607.1";

  src = fetchFromGitHub {
    owner = "jmfederico";
    repo = "pi-web";
    rev = "v${version}";
    hash = "sha256-llMtBYOqH92KCrz6lUiJRG0rQgwGZQpeCZ9LU8VFPgY=";
  };

  # PI WEB imports its Pi peer packages at runtime. Keep them as production
  # dependencies so buildNpmPackage's install phase does not prune them.
  postPatch = ''
        sed -i \
          -e '85,87d' \
          -e '57i\    "@earendil-works/pi-agent-core": "^0.80.8",\n    "@earendil-works/pi-ai": "^0.80.8",\n    "@earendil-works/pi-coding-agent": "^0.80.8",' \
          package.json
        sed -i \
          -e '45,47d' \
          -e '12i\        "@earendil-works/pi-agent-core": "^0.80.8",\n        "@earendil-works/pi-ai": "^0.80.8",\n        "@earendil-works/pi-coding-agent": "^0.80.8",' \
          package-lock.json

        # Upstream's lock file omits integrity fields for three nested dependencies.
        sed -i \
          -e '\|pi-coding-agent/node_modules/@earendil-works/pi-agent-core": {|{n;a\      "integrity": "sha512-nwnOR3SuLYGRFfyQm8ri4Nj5VGVAvAM9GuqQd3u7BUQj0d6hmD2F8w7OHAAjThE3CuySIdM+v8E22QJG6/RfCg==",
    }' \
          -e '\|pi-coding-agent/node_modules/@earendil-works/pi-ai": {|{n;a\      "integrity": "sha512-Moe/H8c87yacDGK9dPbWphZNjVsrb3nTrIHycOQJAkFEnY9PYxOOd74+ny44kATfPU9Dm7aTHefar3pZF+UKUA==",
    }' \
          -e '\|pi-coding-agent/node_modules/@earendil-works/pi-tui": {|{n;a\      "integrity": "sha512-c2JO29PbhKPEQ6fgHQKAl0WhwuFqzWfzspMmP+8B5tpDuP+0mvarRbKKg8gq4b+pQx/QX+6aVS4ko7deoyjQjg==",
    }' \
          package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-velWqdrwDMSD6Orti6oPJPxvGo5kA87B0fP+WtIOd9Y=";

  nativeBuildInputs = [ python3 ];

  meta = {
    description = "Web UI for persistent Pi Coding Agent sessions";
    homepage = "https://pi-web.dev/";
    license = lib.licenses.mit;
    mainProgram = "pi-web";
    platforms = lib.platforms.linux;
  };
}
