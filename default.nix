{ lib
, stdenv
, testers
, zig_0_12
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dt";
  version = "1.3.1";

  src = lib.cleanSource ./.;

  nativeBuildInputs = [ zig_0_12.hook ];

  passthru.tests.version = testers.testVersion { package = finalAttrs.finalPackage; };

  meta = {
    homepage = "https://dt.plumbing";
    description = "Duct tape for your unix pipes";
    longDescription = ''
      dt is a utility and programming language. The utility is intended for
      ergonomic in-the-shell execution. The language is straightforward (in
      the most literal sense) with a minimal syntax that allows for
      high-level, higher-order programming.

      It's meant to supplement (not replace!) other tools like awk, sed,
      xargs, and shell built-ins. Something like the Perl one-liners popular
      yesteryear, but hopefully easier to read and reason through.

      In short, dt is intended to be generally useful, with zero pretense of
      elegance.
    '';
    changelog = "https://github.com/so-dang-cool/dt/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ booniepepper ];
    platforms = lib.platforms.unix;
    mainProgram = "dt";
  };
})
