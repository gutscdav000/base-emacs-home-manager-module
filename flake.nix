{
  description = "defualt base home manager modules for export.";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
  };

  outputs = {self, nixpkgs, ...}@inputs: {
    homeManagerModules = import ./home-manager-modules;
  };
}
