{
  allowUnfree=true;
  android_sdk.accept_license=true;

  # Override the pkgs pseudo package and keys here as another repo 
  packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
    nixGL = import ( fetchTarball "https://github.com/guibou/nixGL/archive/main.tar.gz" ) {
      inherit pkgs;
    };
    android-nixpkgs = pkgs.callPackage (
      import (builtins.fetchGit { url = "https://github.com/tadfisher/android-nixpkgs.git";})
    )
    {
      # Default; can also choose "beta", "preview", or "canary".
      channel = "stable";
    };
  };
}
