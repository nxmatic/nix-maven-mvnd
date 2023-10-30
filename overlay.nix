final: prev: {

    maven-mvnd-m39 = final.callPackage ./derivation.nix {
      mavenVersion = "m39";
      system = "aarch64-darwin";
    };

    maven-mvnd-m40 = final.callPackage ./derivation.nix {  
      mavenVersion = "m40";
      system = "aarch64-darwin";
    };

}
