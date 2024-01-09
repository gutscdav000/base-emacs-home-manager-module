{
  description = "defualt base home manager modules for export.";
  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/master";
  };

  outputs = {self, nixpkgs, nixpkgs-unstable, ...}@inputs: {
    homeManagerModules = import ./home-manager-modules;
    overlays = {
      unstable = (final: prev: {
        unstable = nixpkgs-unstable.legacyPackages.${prev.system};
      });
    };
  };
}
