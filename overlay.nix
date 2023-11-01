self: super: {

  graalvm = super.graalvm-ce;
  
  jdk11 = super.zulu11;

  maven-mvnd-m39 = self.callPackage ./derivation.nix {
    mavenVersion = "m39";
    system = "aarch64-darwin";
  };
  
  maven-mvnd-m40 = self.callPackage ./derivation.nix {  
    mavenVersion = "m40";
    system = "aarch64-darwin";
  };
  
}
