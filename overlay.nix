final: prev: {

  maven-mvnd-m39 = final.callPackage ./maven-mvnd.nix {
    mavenVersion = "m39";
  };

  maven-mvnd-m40 = final.callPackage ./maven-mvnd.nix {  
    mavenVersion = "m40";
  };

}
