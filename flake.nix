{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    mkSpagoDerivation.url = "github:jeslie0/mkSpagoDerivation";
    ps-overlay.url = "github:thomashoneyman/purescript-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, mkSpagoDerivation, ps-overlay }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ mkSpagoDerivation.overlays.default
                       ps-overlay.overlays.default ];
        };
        nodeDependencies = (pkgs.callPackage ./node/default.nix { }).nodeDependencies;
      in
        {
          packages.default =
            pkgs.mkSpagoDerivation {
              spagoYaml = ./spago.yaml;
              spagoLock = ./spago.lock;
              src = ./.;
              nativeBuildInputs = [ pkgs.purs-unstable pkgs.spago-unstable pkgs.esbuild pkgs.purescript-language-server pkgs.node2nix];
              version = "0.1.0";
              buildPhase = ''
                ln -s ${nodeDependencies}/lib/node_modules ./node_modules
                spago bundle
              '';
              installPhase = ''
                mkdir $out;
                cp ${./dist/index.html} $out/index.html;
                cp index.js $out/index.js;
              '';
              shellHook = ''
                if [ ! -L "./node_modules" ]; then
                  ln -s "${nodeDependencies}/lib/node_modules" ./node_modules
                fi
              '';
            };
        }
    );
}
