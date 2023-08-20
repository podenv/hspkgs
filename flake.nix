# When adding override:
# - Add them to the ghc devShell or the all-pkgs list
# - Run `nix run | nix shell nixpkgs#cachix --command cachix push podenv`
{
  description = "hspkgs";
  nixConfig.bash-prompt = "[nix(hspkgs)] ";

  inputs = {
    nixpkgs.url =
      "github:NixOS/nixpkgs/e365e1db48d060b3e31b02ec8177f66f386f39b8";
  };

  outputs = { self, nixpkgs }:
    let
      # Get nixGL to run graphic application outside of nixos
      nixGLSrc = pkgs.fetchFromGitHub {
        owner = "guibou";
        repo = "nixGL";
        rev = "489d6b095ab9d289fe11af0219a9ff00fe87c7c5";
        sha256 = "sha256-E4zUPEUFyVWjVm45zICaHRpfGepfkE9Z2OECV9HXfA4=";
      };

      # Pull master for ghc-9.6 compat
      kubernetes-client = pkgs.fetchFromGitHub {
        owner = "kubernetes-client";
        repo = "haskell";
        rev = "1a262bbb7ed5bdcd4c4df925f2a0eeaeadc00a06";
        sha256 = "sha256-vI6nuV77rpAPXdifO/VmRwHjlRw1nOG5rn4HpF+eHUM=";
      };

      # Unrelease projects
      xstatic = pkgs.fetchFromGitHub {
        owner = "TristanCacqueray";
        repo = "haskell-xstatic";
        rev = "1f72fd2e220414c089492698425c47e7c9566159";
        sha256 = "sha256-6IT8K9noUDIa6ZVjWE3ZrbsElthRCFzBxsCudvpkJ88=";
      };
      servant-effectful = pkgs.fetchFromGitHub {
        owner = "Kleidukos";
        repo = "servant-effectful";
        rev = "21b5a1d7cb209f3b4594167bb0b5a8d632c8a8e1";
        sha256 = "sha256-UUNymCKASnpi6fh26Y5GQD3ufjkY7vbVqWwh76GcnU4=";
      };

      # https://github.com/ndmitchell/record-dot-preprocessor/pull/59
      large-records = pkgs.fetchFromGitHub {
        owner = "TristanCacqueray";
        repo = "large-records";
        rev = "5bcb0eb844f5b5affdd102ebcf3e34e45ac96ed8";
        sha256 = "sha256-W6Xh6aVOsx9rgM6IVin6w7Z3e9yUESSaxfejkyU0ekY=";
      };

      compiler = "ghc962";
      haskellOverrides = {
        overrides = hpFinal: hpPrev:
          let
            mk-xstatic-lib = name:
              hpPrev.callCabal2nix "${name}" "${xstatic}/${name}" { };
            mk-large-rec = name:
              pkgs.haskell.lib.doJailbreak
              (hpPrev.callCabal2nix "${name}" "${large-records}/${name}" { });
          in {
            # Gerrit needs HEAD
            gerrit = let
              src = pkgs.fetchFromGitHub {
                owner = "softwarefactory-project";
                repo = "gerrit-haskell";
                rev = "daa44c450f819f3af2879099ec065c1efb973ef8";
                sha256 = "sha256-g+nMToAq1J8756Yres6xKraQq3QU3FcMjyLvaqVnrKc=";
              };
            in hpPrev.callCabal2nix "gerrit" src { };

            hlint = hpPrev.hlint_3_6_1;

            # lucid-svg needs https://github.com/jeffreyrosenbluth/lucid-svg/pull/17
            lucid-svg = pkgs.haskell.lib.doJailbreak hpPrev.lucid-svg;

            # https://github.com/typeclasses/one-line-aeson-text/pull/1
            one-line-aeson-text =
              pkgs.haskell.lib.doJailbreak hpPrev.one-line-aeson-text;

            # relax req bound for http-data
            req = pkgs.haskell.lib.doJailbreak hpPrev.req;

            # relax bound for base
            zigzag = pkgs.haskell.lib.doJailbreak hpPrev.zigzag;
            bytebuild = pkgs.haskell.lib.doJailbreak hpPrev.bytebuild;
            nixfmt = pkgs.haskell.lib.doJailbreak hpPrev.nixfmt;

            # data-diverse is presently marked as broken because the test don't pass.
            data-diverse = pkgs.haskell.lib.dontCheck
              (pkgs.haskell.lib.overrideCabal hpPrev.data-diverse {
                broken = false;
              });

            # https://github.com/ndmitchell/record-dot-preprocessor/pull/59
            record-dot-preprocessor = let
              src = pkgs.fetchFromGitHub {
                owner = "TristanCacqueray";
                repo = "record-dot-preprocessor";
                rev = "b33a0a443d746d7a1745b1c5f50e0ccfb686cf71";
                sha256 = "sha256-EkSuUjYoUO2WTBseO981VrYZTuuFls2Q+bxovtgq5WI=";
              };
            in hpPrev.callCabal2nix "record-dot-processor" src { };

            large-generics = mk-large-rec "large-generics";
            large-records = mk-large-rec "large-records";

            # https://github.com/fakedata-haskell/fakedata/issues/51
            fakedata = pkgs.haskell.lib.dontCheck hpPrev.fakedata;

            # prometheus-client needs latest version
            prometheus-client =
              pkgs.haskell.lib.overrideCabal hpPrev.prometheus-client {
                version = "1.1.1";
                sha256 = "sha256-anCex0llHYbh46EYkZPT1qdEier48QKXwxzIY/xGRMg=";
                revision = null;
                editedCabalFile = null;
              };

            # json-syntax test needs old tasty
            json-syntax = pkgs.haskell.lib.doJailbreak
              (pkgs.haskell.lib.dontCheck
                (pkgs.haskell.lib.overrideCabal hpPrev.json-syntax {
                  broken = false;
                }));

            fourmolu = hpPrev.fourmolu_0_13_1_0;

            xstatic = mk-xstatic-lib "xstatic";
            xstatic-th = mk-xstatic-lib "xstatic-th";
            lucid-xstatic = mk-xstatic-lib "lucid-xstatic";
            lucid2-xstatic = mk-xstatic-lib "lucid2-xstatic";
            servant-xstatic = mk-xstatic-lib "servant-xstatic";
            xstatic-ace = mk-xstatic-lib "xstatic-ace";
            xstatic-pdfjs = mk-xstatic-lib "xstatic-pdfjs";
            xstatic-htmx = mk-xstatic-lib "xstatic-htmx";
            xstatic-tailwind = mk-xstatic-lib "xstatic-tailwind";
            xstatic-sakura = mk-xstatic-lib "xstatic-sakura";
            xstatic-sweetalert2 = mk-xstatic-lib "xstatic-sweetalert2";
            xstatic-hyperscript = mk-xstatic-lib "xstatic-hyperscript";
            xstatic-remixicon = mk-xstatic-lib "xstatic-remixicon";
            xstatic-sortable = mk-xstatic-lib "xstatic-sortable";
            xstatic-xterm = mk-xstatic-lib "xstatic-xterm";
            xstatic-novnc = mk-xstatic-lib "xstatic-novnc";
            xstatic-winbox = mk-xstatic-lib "xstatic-winbox";
            xstatic-pcm-player = mk-xstatic-lib "xstatic-pcm-player";

            # extra effectful package
            servant-effectful =
              hpPrev.callCabal2nix "servant-effectful" servant-effectful { };

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
          };
      };

      overlay = final: prev:
        let
          mk-exe = prev.haskell.lib.justStaticExecutables;
          hspkgs = prev.haskell.packages.${compiler}.override haskellOverrides;
          hls = prev.haskell-language-server.override {
            supportedGhcVersions = [ "962" ];
          };
          nixGL = import nixGLSrc { pkgs = prev; };
        in {
          hspkgs = hspkgs;
          haskell-language-server = hls;
          hlint = mk-exe hspkgs.hlint;
          weeder = mk-exe hspkgs.weeder;
          ormolu = mk-exe hspkgs.ormolu;
          fourmolu = mk-exe hspkgs.fourmolu;
          calligraphy = mk-exe hspkgs.calligraphy;
          apply-refact = mk-exe hspkgs.apply-refact;
          tasty-discover = mk-exe hspkgs.tasty-discover;
          nixfmt = mk-exe hspkgs.nixfmt;
          cabal-fmt = mk-exe hspkgs.cabal-fmt;
          doctest = mk-exe hspkgs.doctest;
          # replace the global cabal-install by the one provided by the right compiler set
          cabal-install = prev.haskell.packages.${compiler}.cabal-install;
          # cabal-plan = mk-exe hspkgs.cabal-plan;

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

      # Note: add all the above overrides here to validate build with `nix develop`
      ghc = pkgs.hspkgs.ghcWithPackages (p: [
        p.ki
        p.http2
        # p.kubernetes-client
        p.morpheus-graphql-client
        p.generics-sop
        p.jose-jwt
        p.text-time
        p.dhall
        p.turtle
        p.insert-ordered-containers
        p.proto3-suite
        p.json-syntax
        p.cgroup-rts-threads
        p.prometheus-client
        p.ki-effectful
        p.jose
        p.turtle
        p.streaming
        p.gerrit
        p.string-qq
        p.bytebuild
      ]);
      ghc-static = pkgs.hspkgsMusl.ghcWithPackages (p: [ p.relude ]);
      all-pkgs = [
        ghc
        # pkgs.nixGL.auto.nixGLDefault
        # ghc-static
        # pkgs.nixGLIntel
        pkgs.weeder
        pkgs.cabal-install
        # pkgs.cabal-plan
        # pkgs.ormolu
        pkgs.fourmolu
        pkgs.hlint
        pkgs.hpack
        pkgs.apply-refact
        pkgs.hspkgs.hoogle
        pkgs.calligraphy
        pkgs.haskell-language-server
        pkgs.ghcid
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

      # Run this app to print all the path for cachix push
      apps."x86_64-linux".default = {
        type = "app";
        program = builtins.toString
          (pkgs.writers.writeBash "app-wrapper.sh" "echo ${toString all-pkgs}");
      };

      apps."x86_64-linux".static = {
        type = "app";
        program = "${pkgs.hspkgsMusl.hello}/bin/hello";
      };

      packages.x86_64-linux.default =
        pkgs.writers.writeBash "app-wrapper.sh" "echo ${toString all-pkgs}";

      # Start a shell with all the tools
      devShell.x86_64-linux = pkgs.mkShell { buildInputs = all-pkgs; };

      devShells.x86_64-linux.test = pkgs.hspkgs.shellFor {
        packages = p: [ p.proto3-suite ];
        buildInputs = [ pkgs.ghcid pkgs.cabal-install ];
      };
    };
}
