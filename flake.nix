# When adding override:
# - Add them to the ghc devShell or the all-pkgs list
# - Run `nix run | nix shell nixpkgs#cachix --command cachix push podenv`
{
  description = "hspkgs";
  nixConfig.bash-prompt = "[nix(hspkgs)] ";

  inputs = {
    nixpkgs.url =
      "github:NixOS/nixpkgs/22c5bd85d8478e24874ff2b80875506f5c3711a6";
  };

  outputs = { self, nixpkgs }:
    let
      # Get nixGL to run graphic application outside of nixos
      nixGLSrc = pkgs.fetchFromGitHub {
        owner = "guibou";
        repo = "nixGL";
        rev = "7165ffbccbd2cf4379b6cd6d2edd1620a427e5ae";
        sha256 = "sha256-Qc8MXcV+YCPREu8kk6oggk23ZBKLqeQRAIsLbHEviPE=";
      };

      # Pull master for ghc-9.6 compat
      hlint = pkgs.fetchFromGitHub {
        owner = "ndmitchell";
        repo = "hlint";
        rev = "a37e918f17ed90d236e6066fcd2dc7b1e9d5b2d1";
        sha256 = "sha256-qJfIy7b2acZAGovJ0P15nQuo/0bDgPLgz4YibJrbZFY=";
      };
      calligraphy = pkgs.fetchFromGitHub {
        owner = "jonascarpay";
        repo = "calligraphy";
        rev = "bdcfa999f53efe110577657906f48d734263969e";
        sha256 = "sha256-r2t7lr0I6BJQfBkfeV3SaXSBdvl1mCAZzbUTXndcNhw=";
      };
      morpheus-graphql = pkgs.fetchFromGitHub {
        owner = "morpheusgraphql";
        repo = "morpheus-graphql";
        rev = "0.27.3";
        sha256 = "sha256-pwc8cXFTQl6f/VgRXoQjYlBOZoG0goHXwgehB0Bxpls=";
      };
      streaming = pkgs.fetchFromGitHub {
        owner = "haskell-streaming";
        repo = "streaming";
        rev = "0c815bf9043d0f0cbda92b80ef791892e2b7fb43";
        sha256 = "sha256-kxMmrKl03eOWpGl09abeH/FnBG5nm2kb4l048dSuAWA=";
      };
      servant = pkgs.fetchFromGitHub {
        owner = "haskell-servant";
        repo = "servant";
        rev = "79a29b02329909c94edeacbe2d3124d1d985f9f8";
        sha256 = "sha256-JHbf2v421bK6HQo+HEXDP8s9qqP6rlwLkpa5A2GZxl8=";
      };
      kubernetes-client = pkgs.fetchFromGitHub {
        owner = "kubernetes-client";
        repo = "haskell";
        rev = "1a262bbb7ed5bdcd4c4df925f2a0eeaeadc00a06";
        sha256 = "sha256-vI6nuV77rpAPXdifO/VmRwHjlRw1nOG5rn4HpF+eHUM=";
      };

      # Unmerged patch
      # https://github.com/fimad/prometheus-haskell/pull/70
      prometheus-client = pkgs.fetchFromGitHub {
        owner = "9999years";
        repo = "prometheus-haskell";
        rev = "d1809083b0543fff6e997fd1fbbe63e25ae21622";
        sha256 = "sha256-+xo7W1albujRqxe6W4vQer9ufMN0cOhVvFVToavC570=";
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

      compiler = "ghc961";
      haskellOverrides = {
        overrides = hpFinal: hpPrev:
          let
            mk-xstatic-lib = name:
              hpPrev.callCabal2nix "${name}" "${xstatic}/${name}" { };
            mk-servant-lib = name:
              hpPrev.callCabal2nix "sevant${name}" "${servant}/servant${name}"
              { };
            mk-servant-auth-lib = name:
              hpPrev.callCabal2nix "sevant-auth${name}"
              "${servant}/servant-auth/servant-auth${name}" { };
            mk-morpheus-lib = name:
              pkgs.haskell.lib.doJailbreak
              (hpPrev.callCabal2nix "morpheus-graphql-${name}"
                "${morpheus-graphql}/morpheus-graphql-${name}" { });
          in {
            # bump versions for hackage latest
            tls = hpPrev.tls_1_6_0;
            http2 = hpPrev.http2_4_1_2;
            recv = hpPrev.recv_0_1_0;
            lens = hpPrev.lens_5_2_2;
            witch = hpPrev.witch_1_2_0_2;
            byteslice = hpPrev.byteslice_0_2_9_0;
            turtle = hpPrev.turtle_1_6_1;

            # For cabal-plan, but that cause infinit recursion
            # these = hpPrev.these_1_2;
            # semialign = hpPrev.semialign_1_3;
            # base-compat = pkgs.haskell.lib.dontCheck hpPrev.base-compat_0_13_0;
            # cabal-plan = pkgs.haskell.lib.overrideCabal hpPrev.cabal-plan {
            #   version = "0.7.3.0";
            #   sha256 = "sha256-zNxUhUsRFyfZm3ftYzPZ9gx/XuAkAlGy5HiOAFtxXmY=";
            #   revision = null;
            #   editedCabalFile = null;
            # };

            # warp test needs curl
            warp = pkgs.haskell.lib.dontCheck hpPrev.warp_3_3_25;
            warp-tls = hpPrev.warp-tls_3_3_6;

            # https://github.com/well-typed/generics-sop/pull/161
            generics-sop = pkgs.haskell.lib.overrideCabal hpPrev.generics-sop {
              version = "0.5.1.3";
              sha256 = "sha256-7JzHucpHFP1nU4rEpeqYDscxz+DwhMCX+N0oS1Zprwc=";
              revision = null;
              editedCabalFile = null;
            };

            # relax requirements
            modern-uri = pkgs.haskell.lib.doJailbreak hpPrev.modern-uri;
            req = pkgs.haskell.lib.doJailbreak hpPrev.req;
            insert-ordered-containers =
              pkgs.haskell.lib.doJailbreak hpPrev.insert-ordered-containers;
            string-qq = pkgs.haskell.lib.doJailbreak hpPrev.string-qq;
            swagger2 = pkgs.haskell.lib.dontCheck
              (pkgs.haskell.lib.doJailbreak hpPrev.swagger2);
            JuicyPixels = hpPrev.JuicyPixels_3_3_8;
            vector = pkgs.haskell.lib.dontCheck
              (pkgs.haskell.lib.doJailbreak hpPrev.vector_0_13_0_0);
            vector-algorithms = hpPrev.vector-algorithms_0_9_0_1;
            vector-binary-instances =
              pkgs.haskell.lib.doJailbreak hpPrev.vector-binary-instances;
            lucid-svg = pkgs.haskell.lib.doJailbreak hpPrev.lucid-svg;
            zigzag = pkgs.haskell.lib.doJailbreak hpPrev.zigzag;
            proto3-wire = pkgs.haskell.lib.doJailbreak
              (pkgs.haskell.lib.dontCheck hpPrev.proto3-wire);
            one-line-aeson-text =
              pkgs.haskell.lib.doJailbreak hpPrev.one-line-aeson-text;
            bytebuild = pkgs.haskell.lib.doJailbreak hpPrev.bytebuild;
            bugzilla-redhat =
              pkgs.haskell.lib.doJailbreak hpPrev.bugzilla-redhat;
            dhall = pkgs.haskell.lib.doJailbreak hpPrev.dhall;
            weeder = pkgs.haskell.lib.doJailbreak hpPrev.weeder;

            # proto3-suite need a fix
            proto3-suite = pkgs.haskell.lib.dontCheck
              (pkgs.haskell.lib.disableCabalFlag (pkgs.haskell.lib.overrideCabal
                (pkgs.haskell.lib.doJailbreak hpPrev.proto3-suite) {
                  patches = [
                    (pkgs.fetchpatch {
                      url =
                        "https://github.com/awakesecurity/proto3-suite/commit/a2f50e9aa88d3600b681b34f944c319ac101dff8.patch";
                      sha256 =
                        "sha256-bGOmzJnsVuHYTZhvUMMp/QVGA4ZhIKaGhp9Hm0hFN9s=";
                    })
                  ];
                }) "swagger");

            # scientific-notation fix
            scientific-notation =
              pkgs.haskell.lib.overrideCabal hpPrev.scientific-notation {
                patches = [
                  (pkgs.fetchpatch {
                    url =
                      "https://github.com/andrewthad/scientific-notation/commit/956eb989310e3d03d8209564891158078d391376.patch";
                    sha256 =
                      "sha256-JJiN95LxmNjvtccdiqEfTNrnzE5ZvDZ7S8cGwzbc//w=";
                  })
                ];

              };

            # data-diverse is presently marked as broken because the test don't pass.
            data-diverse = pkgs.haskell.lib.dontCheck
              (pkgs.haskell.lib.overrideCabal hpPrev.data-diverse {
                broken = false;
              });

            # https://github.com/alexkazik/qrcode/pull/5
            qrcode-core = pkgs.haskell.lib.doJailbreak hpPrev.qrcode-core;
            qrcode-juicypixels =
              pkgs.haskell.lib.doJailbreak hpPrev.qrcode-juicypixels;

            # ki needs HEAD
            ki = let
              src = pkgs.fetchFromGitHub {
                owner = "awkward-squad";
                repo = "ki";
                rev = "c3edf709f7361e0a25c2d2be2f3077c785616a21";
                sha256 = "sha256-EFV6ng9Ht5JzrSaDOiCqJQZjPMEoWqUzGgFCkb9WA3g=";
              };
            in hpPrev.callCabal2nix "ki" "${src}/ki" { };

            # Gerrit needs HEAD
            gerrit = let
              src = pkgs.fetchFromGitHub {
                owner = "softwarefactory-project";
                repo = "gerrit-haskell";
                rev = "daa44c450f819f3af2879099ec065c1efb973ef8";
                sha256 = "sha256-g+nMToAq1J8756Yres6xKraQq3QU3FcMjyLvaqVnrKc=";
              };
            in hpPrev.callCabal2nix "gerrit" src { };

            # Streaming needs HEAD
            streaming = hpPrev.callCabal2nix "streaming" streaming { };

            # test failure reported: https://github.com/sjakobi/bsb-http-chunked/issues/45
            bsb-http-chunked =
              pkgs.haskell.lib.dontCheck hpPrev.bsb-http-chunked;
            # test failure reported: https://github.com/kowainik/relude/issues/436
            relude = pkgs.haskell.lib.dontCheck
              (pkgs.haskell.lib.doJailbreak hpPrev.relude_1_2_0_0);

            # Servant needs HEAD
            servant = pkgs.haskell.lib.doJailbreak (mk-servant-lib "");
            servant-foreign = mk-servant-lib "-foreign";
            servant-server =
              pkgs.haskell.lib.doJailbreak (mk-servant-lib "-server");
            servant-auth =
              pkgs.haskell.lib.doJailbreak (mk-servant-auth-lib "");
            # servant-auth-server test hangs
            servant-auth-server = pkgs.haskell.lib.doJailbreak
              (pkgs.haskell.lib.dontCheck (mk-servant-auth-lib "-server"));

            # Morpheus needs HEAD
            morpheus-graphql-tests = mk-morpheus-lib "tests";
            morpheus-graphql-app = mk-morpheus-lib "app";
            morpheus-graphql-core = mk-morpheus-lib "core";
            morpheus-graphql-code-gen = mk-morpheus-lib "code-gen";
            morpheus-graphql-client = mk-morpheus-lib "client";
            morpheus-graphql-subscriptions = mk-morpheus-lib "subscriptions";
            jose-jwt = pkgs.haskell.lib.overrideCabal hpPrev.jose-jwt {
              version = "0.9.5";
              sha256 = "sha256-p9wKa/qSA8ldpV2DoE8eoMQjDcMcA1CcsACUjrtBhkc=";
              revision = null;
              editedCabalFile = null;
            };
            jose = hpPrev.jose_0_10;

            # bump apply-refact for hlint
            apply-refact = pkgs.haskell.lib.doJailbreak
              (pkgs.haskell.lib.overrideCabal hpPrev.apply-refact_0_12_0_0 {
                patches = [
                  (pkgs.fetchpatch {
                    url =
                      "https://github.com/mpickering/apply-refact/commit/99cff95285dec909ff32fef3c6284976b74b0855.patch";
                    sha256 =
                      "sha256-W4+3Gj9KvxBmqzrEvvx566EGRc8IRpUdMiPfWTPR7rw=";
                  })
                ];
              });
            hlint = hpPrev.callCabal2nix "hlint" hlint { };
            calligraphy = hpPrev.callCabal2nix "calligraphy" calligraphy { };

            # prometheus-client needs patch for mtl
            prometheus-client = hpPrev.callCabal2nix "prometheus-client"
              "${prometheus-client}/prometheus-client" { };

            # Fourmolu test failure:
            # fourmolu>   region-tests/Main.hs:11:7:
            # fourmolu>   1) region-tests Works with implicit arguments
            # fourmolu>        uncaught exception: IOException of type UserError
            # fourmolu>        user error (Could not find fourmolu executable)
            fourmolu = pkgs.haskell.lib.dontCheck hpPrev.fourmolu_0_12_0_0;
            ormolu = hpPrev.ormolu_0_6_0_1;

            # relax base bound

            # json-syntax test needs old tasty
            json-syntax = pkgs.haskell.lib.doJailbreak
              (pkgs.haskell.lib.dontCheck
                (pkgs.haskell.lib.overrideCabal hpPrev.json-syntax {
                  broken = false;
                }));

            retry = pkgs.haskell.lib.overrideCabal hpPrev.retry {
              version = "0.9.3.1";
              sha256 = "sha256-Yi41EUuSD3b6LhrmUVV1uZc/rBnGefVCbqZXSl0LftY=";
            };

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

            # test failure reported: https://github.com/haskell-distributed/rank1dynamic/issues/26
            rank1dynamic = pkgs.haskell.lib.dontCheck
              (pkgs.haskell.lib.overrideCabal hpPrev.rank1dynamic {
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
            supportedGhcVersions = [ "961" ];
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
    };
}
