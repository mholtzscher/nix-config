{
  lib,
  python3,
  fetchFromGitHub,
}:

python3.pkgs.buildPythonApplication rec {
  pname = "vimhjkl";
  version = "0.4.1";

  src = fetchFromGitHub {
    owner = "S-Sigdel";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-65GvB6MVAMyypiHz/SezgEP2oT2aHNLlCQ9uFFqBCwM=";
  };

  pyproject = true;

  # uv_build is not available in nixpkgs, so substitute with setuptools.
  # The package has no third-party runtime dependencies, so any build
  # backend that copies the source tree into site-packages works.
  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'requires = ["uv_build>=0.11,<0.12"]' 'requires = ["setuptools"]' \
      --replace-fail 'build-backend = "uv_build"' 'build-backend = "setuptools.build_meta:__legacy__"'
  '';

  nativeBuildInputs = with python3.pkgs; [
    pip
    setuptools
    wheel
  ];

  meta = with lib; {
    description = "A terminal trainer that drills advanced Vim techniques in real vim/nvim and grades your keystrokes";
    homepage = "https://github.com/S-Sigdel/vimhjkl";
    license = licenses.mit;
    mainProgram = "vimhjkl";
    platforms = platforms.all;
  };
}
