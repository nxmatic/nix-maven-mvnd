{
  mavenVersion, system
, pkgs, lib, stdenv
, fetchFromGitHub, buildMavenRepositoryFromLockFile
, makeWrapper, maven, jdk11_headless, rsync
, nix-gitignore
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

  nativeBuildInputs = [ jdk11_headless maven makeWrapper rsync ];

  buildInputs = [
    graalvm
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

    cc -v
    ./mvnw package -DskipTests -Dmaven.repo.local=${mavenRepository}
  '';

  installPhase = ''

  installPhase = let
    system-parts = lib.strings.splitString "-" system;
    arch = system-parts.[0];
    os = system-parts.[1];
  in ''
    set -ex


    # which dist I'm building
    system="$( system )"
    arch="$( arch )"
    version=${version}

    # copy out the distribution
    mkdir -p $out
    rsync -av "dist-${mavenVersion}/target/maven-mvnd-$version-${mavenVersion}-$system-$arch/" $out

    addToSearchPath PATH $out/bin

    # create a wrapper that will automatically set the classpath
    # this should be the paths from the dependency derivation
    # makeWrapper ${jdk11_headless}/bin/java $out/bin/${pname} \
    #      --add-flags "-jar $out/${name}.jar"
  '';
}
