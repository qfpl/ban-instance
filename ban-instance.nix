{ mkDerivation, base, stdenv, template-haskell }:
mkDerivation {
  pname = "ban-instance";
  version = "0.1.0.0";
  src = ./.;
  libraryHaskellDepends = [ base template-haskell ];
  testHaskellDepends = [ base ];
  homepage = "https://github.com/qfpl/ban-instance#readme";
  description = "For when a type should never be an instance of a class";
  license = stdenv.lib.licenses.bsd3;
}
