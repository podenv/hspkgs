# When adding override:
# - Add them to the ghc devShell or the all-pkgs list
# - Run `nix run | nix shell nixpkgs#cachix --command cachix push podenv`
{
  description = "hspkgs";
  nixConfig.bash-prompt = "[nix(hspkgs)] ";

  inputs = {
    nixpkgs.url =
      "github:NixOS/nixpkgs/00d73d5385b63e868bd11282fb775f6fe4921fb5";
  };

  outputs = { self, nixpkgs }:
    let
      # Get nixGL to run graphic application outside of nixos
      nixGLSrc = pkgs.fetchFromGitHub {
        owner = "guibou";
        repo = "nixGL";
        rev = "047a34b2f087e2e3f93d43df8e67ada40bf70e5c";
        sha256 = "sha256-Sz0uWspqvshGFbT+XmRVVayuW514rNNLLvrre8jBLLU=";
      };

      # Grab latest monomer because nixpkgs is a bit outdated
      monomer = pkgs.fetchFromGitHub {
        owner = "fjvallarino";
        repo = "monomer";
        rev = "5852155b727027e20f5bd0793b9e8df7354f9afc";
        sha256 = "sha256-NB1UxngglC77OJ0QEBwLsIQ3XKfkTVXoMMoiFdGQij8=";
      };
      # Need servant last version to build with ghc-9.2.3 base
      servant = pkgs.fetchFromGitHub {
        owner = "haskell-servant";
        repo = "servant";
        rev = "f0e2316895ee5fda52ba9d5b2b7e10f8a80a9019";
        sha256 = "sha256-+pLzHRUIFmS2uN1jr9/UxS64E7t3f0Fo3r+83X+yqlk=";
      };
      # Need latest weeder for ghc-9.2 support
      weeder = pkgs.fetchFromGitHub {
        owner = "ocharles";
        repo = "weeder";
        rev = "2.4.0";
        sha256 = "sha256-aYcaFfu9ocwiSnFndfE9Ro70QDY560lrrT6w+uJY5eY=";
      };
      # Grab latest ormolu
      ormolu = pkgs.fetchFromGitHub {
        owner = "tweag";
        repo = "ormolu";
        rev = "0.5.0.1";
        sha256 = "sha256-i4ePvBjHQtzGQr4LsH8n3oN+VxnKp8EhlWAz/uIB6Ik=";
      };
      # Grab latest fourmolu
      fourmolu = pkgs.fetchFromGitHub {
        owner = "fourmolu";
        repo = "fourmolu";
        rev = "v0.8.0.0";
        sha256 = "sha256-SAVL4k+uxZKjlQq8ckXPpTADWx2G+6Hu8yNuW4jaQ8M=";
      };
      # Grab ghc922 pr
      kubernetes-client = pkgs.fetchFromGitHub {
        owner = "TristanCacqueray";
        repo = "kubernetes-client-haskell";
        rev = "dd9ebc14958173b87b30c40d92ec38c2601250d1";
        sha256 = "sha256-Y0rls7MPIHI8aq3HMzJp22f/hCr+R96hlLsATyc/u60=";
      };
      # following nixpkgs version are broken, pull latest code
      morpheus-graphql = pkgs.fetchFromGitHub {
        owner = "morpheusgraphql";
        repo = "morpheus-graphql";
        rev = "0.20.0";
        sha256 = "sha256-c4fR2hffcfjSIVY8yT7/3HHxiB0b1tOrXXbvs8h3XNA=";
      };
      text-time = pkgs.fetchFromGitHub {
        owner = "klangner";
        repo = "text-time";
        rev = "1ff65c2c8845e3fdd99900054f0596818a95c316";
        sha256 = "sha256-yszIIBEr19aLJtMtuv18e/76TpGWFV30/c0XXM6uavg=";
      };
      json-syntax = pkgs.fetchFromGitHub {
        owner = "byteverse";
        repo = "json-syntax";
        rev = "43d53312b318451b4ef5bd368bfd326a7af4970f";
        sha256 = "sha256-SA6o2yY27GUB2ELWV/McSjX6sRYuT3o7AcnMQBJKcw8=";
      };

      compiler = "ghc924";
      haskellOverrides = {
        overrides = hpFinal: hpPrev:
          let
            mk-servant-lib = name:
              hpPrev.callCabal2nix "sevant${name}" "${servant}/servant${name}"
              { };
            mk-morpheus-lib = name:
              hpPrev.callCabal2nix "morpheus-graphql-${name}"
              "${morpheus-graphql}/morpheus-graphql-${name}" { };
          in {
            # Latest doctest is necessary for latest relude
            doctest = hpPrev.doctest_0_20_0;

            # bump tls for latest
            tls = hpPrev.tls_1_6_0;

            # bump relude for ghc9
            relude = hpPrev.relude_1_1_0_0;

            # bump timerep to build with latest time
            timerep = hpPrev.timerep_2_1_0_0;

            # bump houath2 to build with latest binary and bytestring
            hoauth2 = hpPrev.hoauth2_2_5_0;

            # bump apply-refact for hlint
            apply-refact = hpPrev.apply-refact_0_10_0_0;

            # bump sdl2 for latest monomer
            sdl2 = pkgs.haskell.lib.dontCheck hpPrev.sdl2_2_5_3_3;

            # don't check monomer because test needs dri
            monomer = pkgs.haskell.lib.dontCheck
              ((hpPrev.callCabal2nix "monomer" monomer { }));

            text-time = hpPrev.callCabal2nix "text-time" text-time { };
            # json-syntax test needs old tasty
            json-syntax = pkgs.haskell.lib.dontCheck
              (hpPrev.callCabal2nix "json-syntax" json-syntax { });

            morpheus-graphql-tests = mk-morpheus-lib "tests";
            morpheus-graphql-core = mk-morpheus-lib "core";
            morpheus-graphql-code-gen = mk-morpheus-lib "code-gen";
            morpheus-graphql-client = mk-morpheus-lib "client";

            servant = mk-servant-lib "";
            servant-foreign = mk-servant-lib "-foreign";
            servant-server = mk-servant-lib "-server";

            # upgrade to latest gerrit for bytestring>0.11 fix
            gerrit = pkgs.haskell.lib.overrideCabal hpPrev.gerrit {
              version = "0.1.5.1";
              sha256 = "sha256-y7rSbOD8EpRiRahrG9BkL9fF0RoHLr5WzuT7mi4jQ64=";
            };

            # there is a test failure: resolveGroupController should resolve a direct mount root
            cgroup-rts-threads = pkgs.haskell.lib.dontCheck
              (pkgs.haskell.lib.overrideCabal hpPrev.cgroup-rts-threads {
                broken = false;
              });

            kubernetes-client-core = pkgs.haskell.lib.dontCheck
              (hpPrev.callCabal2nix "kubernetes-client-core"
                "${kubernetes-client}/kubernetes" { });

            kubernetes-client = pkgs.haskell.lib.dontCheck
              (hpPrev.callCabal2nix "kubernetes-client"
                "${kubernetes-client}/kubernetes-client" { });

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
          nixGL = import nixGLSrc { pkgs = prev; };
        in {
          hspkgs = hspkgs;
          weeder = mk-exe hspkgs.weeder;
          ormolu = mk-exe hspkgs.ormolu;
          fourmolu = mk-exe hspkgs.fourmolu;
          calligraphy = mk-exe hspkgs.calligraphy;
          apply-refact = mk-exe hspkgs.apply-refact;

          hspkgsMusl = prev.pkgsMusl.haskell.packages.${compiler}.override
            haskellOverrides;

          roboto_font =
            "${prev.roboto}/share/fonts/truetype/Roboto-Regular.ttf";
          nixGLIntel = nixGL.nixGLIntel;
          nixGL = nixGL;
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
        p.kubernetes-client
        p.morpheus-graphql-client
        p.text-time
        p.json-syntax
        p.cgroup-rts-threads
      ]);
      ghc-static = pkgs.hspkgsMusl.ghcWithPackages (p: [ p.relude ]);
      # Borrowed from https://github.com/dhall-lang/dhall-haskell/blob/master/nix/shared.nix
      mk-static-haskell = drv:
        pkgs.haskell.lib.appendConfigureFlags
        (pkgs.haskell.lib.disableLibraryProfiling
          (pkgs.haskell.lib.disableSharedExecutables
            (pkgs.haskell.lib.justStaticExecutables
              (pkgs.haskell.lib.dontCheck drv)))) [
                "--enable-executable-static"
                "--extra-lib-dirs=${
                  pkgs.pkgsMusl.ncurses.override { enableStatic = true; }
                }/lib"
                "--extra-lib-dirs=${
                  pkgs.pkgsMusl.gmp6.override { withStatic = true; }
                }/lib"
                "--extra-lib-dirs=${pkgs.pkgsMusl.zlib.static}/lib"
                "--extra-lib-dirs=${
                  pkgs.pkgsMusl.libsodium.overrideAttrs
                  (old: { dontDisableStatic = true; })
                }/lib"
                "--extra-lib-dirs=${
                  pkgs.pkgsMusl.libffi.overrideAttrs
                  (old: { dontDisableStatic = true; })
                }/lib"
              ];
      all-pkgs = [
        ghc
        ghc-static
        pkgs.nixGLIntel
        pkgs.weeder
        pkgs.ormolu
        pkgs.fourmolu
        pkgs.hlint
        pkgs.apply-refact
        pkgs.hspkgs.hoogle
        # pkgs.calligraphy
        pkgs.haskell-language-server
        # A sample static build env to cache its requirements
        (mk-static-haskell pkgs.hspkgsMusl.hello).env
      ];

    in {
      overlays.hspkgs = overlay;
      pkgs = pkgs;
      hoogle-shell = hp: pkg:
        hp.shellFor {
          packages = p: [ pkg ];
          buildInputs = [
            (pkgs.writeScriptBin "run"
              "exec hoogle server -p 8080 --local --haskell;")
          ];
          withHoogle = true;
        };
      mk-nixgl-command = drv: command:
        pkgs.writeScriptBin "run-nixgl-command" ''
          #!/bin/sh
          export ROBOTO_TTF="${pkgs.roboto_font}"
          exec ${pkgs.nixGLIntel}/bin/nixGLIntel ${drv}/bin/${command}
        '';
      mk-static-haskell = mk-static-haskell;

      # Start a shell with all the tools
      packages."x86_64-linux".devShell."x86_64-linux" =
        pkgs.mkShell { buildInputs = all-pkgs; };

      # Run this app to print all the path for cachix push
      apps."x86_64-linux".default = {
        type = "app";
        program = builtins.toString
          (pkgs.writers.writeBash "app-wrapper.sh" "echo ${toString all-pkgs}");
      };

      packages.x86_64-linux.default =
        pkgs.writers.writeBash "app-wrapper.sh" "echo ${toString all-pkgs}";

      devShell.x86_64-linux = pkgs.mkShell { buildInputs = [ ghc ]; };
    };
}
