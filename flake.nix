# When adding override:
# - Add them to the ghc devShell or the all-pkgs list
# - Run `nix run | nix shell nixpkgs#cachix --command cachix push podenv`
{
  description = "hspkgs";
  nixConfig.bash-prompt = "[nix(hspkgs)] ";

  inputs = {
    nixpkgs.url =
      "github:NixOS/nixpkgs/00d73d5385b63e868bd11282fb775f6fe4921fb5";
    nixGL.url = "github:guibou/nixGL/047a34b2f087e2e3f93d43df8e67ada40bf70e5c";
    nixGL.inputs.nixpkgs.follows = "nixpkgs";
    # Grab latest monomer because nixpkgs is a bit outdated
    monomer.url =
      "github:fjvallarino/monomer/5852155b727027e20f5bd0793b9e8df7354f9afc";
    monomer.flake = false;
    # Need servant last version to build with ghc-9.2.3 base
    servant.url =
      "github:haskell-servant/servant/f0e2316895ee5fda52ba9d5b2b7e10f8a80a9019";
    servant.flake = false;
    # Need latest weeder for ghc-9.2 support
    weeder.url = "github:ocharles/weeder/2.4.0";
    weeder.flake = false;
    # Need latest relude for ghc-9.2
    relude.url = "github:kowainik/relude/v1.1.0.0";
    relude.flake = false;
    # Grab latest ormolu
    ormolu.url = "github:tweag/ormolu/0.5.0.1";
    ormolu.flake = false;
    # Grab latest fourmolu
    fourmolu.url = "github:fourmolu/fourmolu/v0.8.0.0";
    fourmolu.flake = false;
  };

  outputs = { self, nixpkgs, monomer, servant, relude, weeder, ormolu, fourmolu
    , nixGL }:
    let
      compiler = "ghc924";
      haskellOverrides = {
        overrides = hpFinal: hpPrev:
          let
            mk-servant-lib = name:
              hpPrev.callCabal2nix "sevant${name}" "${servant}/servant${name}"
              { };
          in {
            sdl2 = pkgs.haskell.lib.dontCheck hpPrev.sdl2_2_5_3_3;
            # Latest doctest is necessary for latest relude
            doctest = hpPrev.doctest_0_20_0;

            # don't check monomer because test needs dri
            monomer = pkgs.haskell.lib.dontCheck
              ((hpPrev.callCabal2nix "monomer" monomer { }));

            servant = mk-servant-lib "";
            servant-foreign = mk-servant-lib "-foreign";
            servant-server = mk-servant-lib "-server";

            relude = hpPrev.callCabal2nix "relude" relude { };

            ormolu = hpPrev.callCabal2nix "ormolu" ormolu { };
            fourmolu = pkgs.haskell.lib.dontCheck
              (hpPrev.callCabal2nix "fourmolu" fourmolu { });
            weeder = hpPrev.callCabal2nix "weeder" weeder { };
          };
      };
      overlay = final: prev:
        let
          mk-exe = prev.haskell.lib.justStaticExecutables;
          hspkgs = prev.haskell.packages.${compiler}.override haskellOverrides;
        in {
          hspkgs = hspkgs;
          weeder = mk-exe hspkgs.weeder;
          ormolu = mk-exe hspkgs.ormolu;
          fourmolu = mk-exe hspkgs.fourmolu;
          calligraphy = mk-exe hspkgs.calligraphy;

          roboto_font =
            "${prev.roboto}/share/fonts/truetype/Roboto-Regular.ttf";
          nixGLIntel = nixGL.packages.x86_64-linux.nixGLIntel;
        };

      # Test
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ overlay ];
      };
      ghc = pkgs.hspkgs.ghcWithPackages (p: [
        p.relude
        p.lens
        p.dhall
        p.monomer
        p.servant-websockets
        p.effectful
      ]);
      all-pkgs = [
        ghc
        pkgs.nixGLIntel
        pkgs.weeder
        pkgs.ormolu
        pkgs.fourmolu
        # pkgs.calligraphy
        pkgs.haskell-language-server
      ];

    in {
      pkgs = pkgs;
      mk-nixgl-command = drv: command:
        pkgs.writeScriptBin "run-nixgl-command" ''
          #!/bin/sh
          export ROBOTO_TTF="${pkgs.roboto_font}"
          exec ${pkgs.nixGLIntel}/bin/nixGLIntel ${drv}/bin/${command}
        '';

      overlays.hspkgs = overlay;
      packages."x86_64-linux".devShell."x86_64-linux" =
        pkgs.mkShell { buildInputs = all-pkgs; };
      apps."x86_64-linux".default = {
        type = "app";
        program = builtins.toString
          (pkgs.writers.writeBash "app-wrapper.sh" "echo ${toString all-pkgs}");
      };
    };
}
