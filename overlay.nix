self: super: {

  maven-jdk21-graalvm = super.graalvm-ce;
  
  maven-jdk20-temurin = super.temurin-bin-20;

  maven-jdk19-temurin = super.temurin-bin-19;

  maven-jdk17-zulu = super.zulu17; # nuxeo build platform

  maven-jdk11-temurin = super.temurin-bin-11;

  maven-jdk11-zulu = super.zulu11; # nos build platform

  maven-mvnd-m39 = self.callPackage ./derivation.nix {
    mavenVersion = "m39";
    system = "aarch64-darwin";
  };
  
  maven-mvnd-m40 = self.callPackage ./derivation.nix {  
    mavenVersion = "m40";
    system = "aarch64-darwin";
  };
  
}
