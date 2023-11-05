{
  mavenVersion, system
, pkgs, lib, stdenv
, fetchFromGitHub, buildMavenRepositoryFromLockFile
, nix-gitignore, makeWrapper
, coreutils, rsync
, maven
, maven-jdk21-graalvm
, maven-jdk20-temurin, maven-jdk19-temurin, maven-jdk11-temurin
, maven-jdk17-zulu, maven-jdk11-zulu
}:

let
  mavenRepository = buildMavenRepositoryFromLockFile { file = ./mvn2nix-lock.json; };

  binDir = "target/bin";

in stdenv.mkDerivation rec {

  version = "1.0-m8";
  
  name = "maven-mvnd-${mavenVersion}";

  meta = with lib; {
    description = "The maven daemon based on ${mavenVersion}.";
    conflicts = lib.optional stdenv.isLinux [
      "maven-mvnd-m39"
      "maven-mvnd-m40"      
    ];
  };

  src = fetchFromGitHub { 
    owner = "nxmatic";
    repo = "maven-mvnd";
    rev = "develop";
    hash = "sha256-wMqAY1qwtuDXT60VDti7+nZ2nPkpTIvePEsySpVhuRA=";
  };

  nativeBuildInputs = [ pkgs.makeWrapper pkgs.rsync pkgs.yq-go
                        pkgs.maven pkgs.maven-jdk21-graalvm
                      ];

  buildInputs = [
    pkgs.coreutils
    pkgs.maven-jdk11-temurin
    pkgs.maven-jdk11-zulu
    pkgs.maven-jdk19-temurin
    pkgs.maven-jdk20-temurin
    pkgs.maven-jdk21-graalvm
  ];

  buildPhase = ''
    mkdir -p "${binDir}"

    export CC=${binDir}/cc
    export CLANG=${binDir}/clang

    ln -s ${coreutils}/bin/gmktemp ${binDir}/mktemp
    ln -s /usr/bin/cc $CC
    ln -s /usr/bin/clang $CLANG

    export JAVA_HOME=${pkgs.maven-jdk21-graalvm};
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

    # create the shared toolchains
    cat <<! | yq --input-format=yaml --output-format=xml > $out/mvn/conf/toolchains.xml
    +p_xml: version="1.0" encoding="UTF-8"
    toolchains:
      # JDK toolchains
      toolchain:
        - type: jdk
          provides:
            version: "11"
            vendor: Azul Systems, Inc.
          configuration:
            jdkHome: ${pkgs.maven-jdk11-zulu}
        - type: jdk
          provides:
            version: "17"
            vendor: Azul Systems, Inc.
          configuration:
            jdkHome: ${pkgs.maven-jdk17-zulu}
        - type: jdk
          provides:
            version: "11"
            vendor: Eclipse Adoptium
          configuration:
            jdkHome: ${pkgs.maven-jdk11-temurin}
        - type: jdk
          provides:
            version: "19"
            vendor: Eclipse Adoptium
          configuration:
            jdkHome: ${pkgs.maven-jdk19-temurin}
        - type: jdk
          provides:
            version: "20"
            vendor: Eclipse Adoptium
          configuration:
            jdkHome: ${pkgs.maven-jdk20-temurin}
        - type: jdk
          provides:
            version: "21"
            vendor: GraalVM Community
          configuration:
            jdkHome: ${pkgs.maven-jdk21-graalvm}
      #      
      #  <toolchain>
      #    <type>netbeans</type>
      #    <provides>
      #      <version>5.5</version>
      #    </provides>
      #    <configuration>
      #      <installDir>/path/to/netbeans/5.5</installDir>
      #    </configuration>
      #  </toolchain
    !
    # create wrappers
    typeset -a wrapperArgs=( )
    wrapperArgs+=( --prefix 'PATH' ':' '${lib.makeBinPath [ pkgs.maven-jdk19-temurin pkgs.coreutils ]}' )
    wrapperArgs+=( --set JAVA_HOME ${pkgs.maven-jdk19-temurin} )

    wrapProgram $out/bin/mvnd "${dollar}{wrapperArgs[@]}"
    wrapProgram $out/bin/mvnd.sh "${dollar}{wrapperArgs[@]}"
  '';
}
