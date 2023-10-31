{
  mavenVersion, system
, pkgs, lib, stdenv
, fetchFromGitHub, buildMavenRepositoryFromLockFile
, nix-gitignore, makeWrapper
, coreutils, rsync
, graalvm-ce, maven
}:

let
  mavenRepository = buildMavenRepositoryFromLockFile { file = ./mvn2nix-lock.json; };

  graalvm = pkgs.graalvm-ce;
  coreutils = pkgs.coreutils;

  binDir = "target/bin";

in stdenv.mkDerivation rec {

  version = "1.0-m8";
  
  pname = "maven-mvnd-${mavenVersion}";
  name = "${pname}-${version}-${system}";

  meta = with lib; {
    description = "The maven daemon based on ${mavenVersion}.";
    conflicts = lib.optional stdenv.isLinux [
      "maven-mvnd-m39"
      "maven-mvnd-m40"      
    ];
  };

  src = fetchFromGitHub { 
    owner = "apache";
    repo = "maven-mvnd";
    rev = "1.0-m8";
    hash = "sha256-tC1nN81aimfA0CWQAU6J/QEXO2mmSQln+dkiB2jyqfI=";
  };

  patches = [
    ./nix-build.patch
  ];

  nativeBuildInputs = [ graalvm-ce maven makeWrapper rsync ];

  buildInputs = [
    coreutils
  ];

  buildPhase = ''
    echo "Patching maven build for nix"

    patch -p0 $patches/nix-build.patch

    echo "Building with maven repository ${mavenRepository}"

    mkdir -p "${binDir}"

    export CC=${binDir}/cc
    export CLANG=${binDir}/clang

    ln -s ${coreutils}/bin/gmktemp ${binDir}/mktemp
    ln -s /usr/bin/cc $CC
    ln -s /usr/bin/clang $CLANG

    export JAVA_HOME=${graalvm};
    export PATH=${binDir}:$PATH

    ./mvnw package -DskipTests -Dmaven.repo.local=${mavenRepository}
  '';

  installPhase = let
    dollar = "$";
  in ''
    # extract the os and arch
    system="${system}"
    arch="${dollar}{system%%-*}"
    os="${dollar}{system##*-}"

    dist="dist-${mavenVersion}/target/maven-mvnd-${version}-${mavenVersion}-$os-$arch"

    # copy out the distribution
    mkdir -p $out
    rsync -av "$dist/." $out

    # create wrappers
    typeset -a wrapperArgs=( )
    wrapperArgs+=( --prefix 'PATH' ':' '${lib.makeBinPath [ graalvm coreutils ]}' )
    wrapperArgs+=( --set JAVA_HOME $JAVA_HOME )

    wrapProgram $out/bin/mvnd "${dollar}{wrapperArgs[@]}"
    wrapProgram $out/bin/mvnd.sh "${dollar}{wrapperArgs[@]}"
  '';
}
