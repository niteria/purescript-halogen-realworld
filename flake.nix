{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    mkSpagoDerivation.url = "github:jeslie0/mkSpagoDerivation";
    ps-overlay.url = "github:thomashoneyman/purescript-overlay";

    slimlock.url = "github:thomashoneyman/slimlock";
    slimlock.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      mkSpagoDerivation,
      ps-overlay,
      slimlock,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            mkSpagoDerivation.overlays.default
            ps-overlay.overlays.default
            slimlock.overlays.default
          ];
        };
        src = ./.;
        modules = pkgs.slimlock.buildPackageLock { inherit src; };
      in
      {
        packages.default = pkgs.mkSpagoDerivation {
          spagoYaml = ./spago.yaml;
          spagoLock = ./spago.lock;
          inherit src;
          nativeBuildInputs = [
            pkgs.purs-unstable
            pkgs.spago-unstable
            pkgs.esbuild
            pkgs.purescript-language-server
          ];
          version = "0.1.0";
          buildPhase = ''
            ln -s ${modules}/js/node_modules ./node_modules
            spago bundle
          '';
          installPhase = ''
            mkdir $out;
            cp ${./dist/index.html} $out/index.html;
            cp index.js $out/index.js
          '';
          shellHook = ''
            if [ ! -L "./node_modules" ]; then
              ln -s "${modules}/js/node_modules" ./node_modules
            fi
          '';
        };

        packages.update-spago-lock = pkgs.writeShellScriptBin "update-spago-lock" ''
          rm -f spago.lock
          PATH="${pkgs.purs-unstable}/bin:$PATH" ${pkgs.spago-unstable}/bin/spago fetch
        '';
      }
    );
}
