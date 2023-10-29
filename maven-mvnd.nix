{
  mavenVersion
, pkgs, lib, stdenv
, fetchFromGitHub, buildMavenRepositoryFromLockFile
, makeWrapper, maven, jdk11_headless, rsync
, nix-gitignore
}:

let
  mavenRepository = buildMavenRepositoryFromLockFile { file = ./mvn2nix-lock.json; };
in stdenv.mkDerivation rec {
  pname = "maven-mvnd-${mavenVersion}";
  version = "1.0-m8";
  name = "${pname}-${version}";

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

  buildPhase = ''
    echo "Patching maven build for nix"
    patch -p0 $patches/nix-build.patch

    echo "Building with maven repository ${mavenRepository}"
    mvn package -DskipTests -Dmaven.repo.local=${mavenRepository}
  '';

  installPhase = ''

    set -ex

    system() { 
      uname -s | tr '[:upper:]' '[:lower:]'
    }

    arch() {
      local machine=$( uname -m )
      case $machine in
        'arm64') echo 'aarch64' ;;
        'amd64'|'x86_64') echo 'amd64' ;;
         *) echo $machine ;;
      esac
    }

    # which dist I'm building
    system="$( system )"
    arch="$( arch )"
    version=${version}

    # copy out the distribution
    mkdir -p $out
    rsync -av "dist-${mavenVersion}/target/maven-mvnd-$version-${mavenVersion}-$system-$arch/" $out

    # create a wrapper that will automatically set the classpath
    # this should be the paths from the dependency derivation
    # makeWrapper ${jdk11_headless}/bin/java $out/bin/${pname} \
    #      --add-flags "-jar $out/${name}.jar"
  '';
}
