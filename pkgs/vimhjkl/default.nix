{
  lib,
  python3,
  fetchzip,
}:

python3.pkgs.buildPythonApplication rec {
  pname = "vimhjkl";
  version = "0.6.0";

  src = fetchzip {
    url = "https://github.com/S-Sigdel/vimhjkl/archive/refs/tags/v${version}.tar.gz";
    hash = "sha256-uBXz2O2PwtnmibaR4e/l+lKIUh7WN2Hvh6nUfpUuEeA=";
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
