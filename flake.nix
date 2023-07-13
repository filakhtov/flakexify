{
  description = "A collection of packages that I use on my various Nix-enabled systems";

  inputs.nixpkgs.url = "nixpkgs/nixos-23.05";

  outputs = { nixpkgs, self, ... }:
    let
      lib = nixpkgs.lib;

      getDirectories = path: builtins.attrNames (
        lib.filterAttrs (k: v: v == "directory") (builtins.readDir path)
      );
      forEach = collection: fn: builtins.foldl' fn { } collection;

      importPackage = path: nixpkgs:
        let
          callPackage = lib.callPackageWith (nixpkgs // self);
          currentSystem = nixpkgs.system;
          isSupportedSystem = systems: builtins.elem currentSystem systems;
          package = callPackage "${self}/pkgs/${path}" { };
        in
        lib.optionalAttrs (isSupportedSystem package.supportedSystems) {
          "${package.name}" = package;
        };

      pkgNames = getDirectories ./pkgs;
      loadPackage = nixpkgs: packages: path: packages // importPackage path nixpkgs;
      loadPackages = nixpkgs: forEach pkgNames (loadPackage nixpkgs);

      genPackages = result: system: result // {
        "${system}" = loadPackages (import nixpkgs { system = system; });
      };

      modNames = getDirectories ./modules;
      importModule = path: import "${self}/modules/${path}" self;
      loadModule = modules: path: modules // importModule path;
      genModules = forEach modNames loadModule;
    in
    {
      nixosModules = genModules;
      packages = forEach lib.systems.flakeExposed genPackages;
    };
}
