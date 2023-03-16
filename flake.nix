# When adding override:
# - Add them to the ghc devShell or the all-pkgs list
# - Run `nix run | nix shell nixpkgs#cachix --command cachix push podenv`
{
  description = "hspkgs";
  nixConfig.bash-prompt = "[nix(hspkgs)] ";

  inputs = {
    nixpkgs.url =
      "github:NixOS/nixpkgs/a738911124aac19232b0839342f970e97da0b7da";
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

      # Grab ghc92 pr
      kubernetes-client = pkgs.fetchFromGitHub {
        owner = "TristanCacqueray";
        repo = "kubernetes-client-haskell";
        rev = "dd9ebc14958173b87b30c40d92ec38c2601250d1";
        sha256 = "sha256-Y0rls7MPIHI8aq3HMzJp22f/hCr+R96hlLsATyc/u60=";
      };
      # Need latest for ghc92
      distributed-static = pkgs.fetchFromGitHub {
        owner = "haskell-distributed";
        repo = "distributed-static";
        rev = "03604c7db49fd74a925cba19fe97d5c9f97d8eb4";
        sha256 = "sha256-4QWCCiJ67CKWrEgAY0mTlZLQVjzUuvtNg55J8ZcKSyI=";
      };

      text-time = pkgs.fetchFromGitHub {
        owner = "klangner";
        repo = "text-time";
        rev = "1ff65c2c8845e3fdd99900054f0596818a95c316";
        sha256 = "sha256-yszIIBEr19aLJtMtuv18e/76TpGWFV30/c0XXM6uavg=";
      };

      ki-effecful = pkgs.fetchFromGitHub {
        owner = "TristanCacqueray";
        repo = "ki-effectful";
        rev = "9a666a8a03a70b00b3b8e22b4176b46eea841f9b";
        sha256 = "sha256-vQRH6BlhXahexOzQeLcqeKqzA2ctolqPFykb+5kTs1s=";
      };

      xstatic = pkgs.fetchFromGitHub {
        owner = "TristanCacqueray";
        repo = "haskell-xstatic";
        rev = "387d11b980f1a864cd7c1a3fcfd9ad7786fca964";
        sha256 = "sha256-AVyLUjFlEwat8tQ5s0bXx9LUSG2RTzRwmEGuZw0V+zI=";
      };

      servant-effectful = pkgs.fetchFromGitHub {
        owner = "Kleidukos";
        repo = "servant-effectful";
        rev = "21b5a1d7cb209f3b4594167bb0b5a8d632c8a8e1";
        sha256 = "sha256-UUNymCKASnpi6fh26Y5GQD3ufjkY7vbVqWwh76GcnU4=";
      };

      compiler = "ghc925";
      haskellOverrides = {
        overrides = hpFinal: hpPrev:
          let
            mk-xstatic-lib = name:
              hpPrev.callCabal2nix "${name}" "${xstatic}/${name}" { };
          in {
            # bump tls for latest
            tls = hpPrev.tls_1_6_0;

            # bump timerep to build with latest time
            timerep = hpPrev.timerep_2_1_0_0;

            # bump apply-refact for hlint
            apply-refact = hpPrev.apply-refact_0_11_0_0;
            hlint = hpPrev.hlint_3_5;
            ghc-lib = hpPrev.ghc-lib_9_4_4_20221225;
            ghc-lib-parser = hpPrev.ghc-lib-parser_9_4_4_20221225;
            ghc-lib-parser-ex = hpPrev.ghc-lib-parser-ex_9_4_0_0;
            Cabal-syntax = hpPrev.Cabal-syntax_3_8_1_0;
            fourmolu = hpPrev.fourmolu_0_10_1_0;
            ormolu = hpPrev.ormolu_0_5_1_0;

            text-time = hpPrev.callCabal2nix "text-time" text-time { };
            # json-syntax test needs old tasty
            json-syntax = pkgs.haskell.lib.dontCheck
              (pkgs.haskell.lib.overrideCabal hpPrev.json-syntax {
                broken = false;
              });

            xstatic = mk-xstatic-lib "xstatic";
            xstatic-th = mk-xstatic-lib "xstatic-th";
            lucid-xstatic = mk-xstatic-lib "lucid-xstatic";
            lucid2-xstatic = mk-xstatic-lib "lucid2-xstatic";
            servant-xstatic = mk-xstatic-lib "servant-xstatic";

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
            ki-effectful = pkgs.haskell.lib.dontCheck
              (hpPrev.callCabal2nix "ki-effectful" ki-effecful { });
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
            distributed-static =
              hpPrev.callCabal2nix "distributed-static" distributed-static { };

            kubernetes-client-core = pkgs.haskell.lib.dontCheck
              (hpPrev.callCabal2nix "kubernetes-client-core"
                "${kubernetes-client}/kubernetes" { });

            kubernetes-client = pkgs.haskell.lib.dontCheck
              (hpPrev.callCabal2nix "kubernetes-client"
                "${kubernetes-client}/kubernetes-client" { });

            weeder = pkgs.haskell.lib.overrideCabal hpPrev.weeder {
              version = "2.4.1";
              sha256 = "sha256-KV4ROsWabRBD8CkXJzqi3BEZvIw/uNN7xu8GDTDiJ/w=";
            };
          };
      };

      overlay = final: prev:
        let
          mk-exe = prev.haskell.lib.justStaticExecutables;
          hspkgs = prev.haskell.packages.${compiler}.override haskellOverrides;
          hls = prev.haskell-language-server.override {
            supportedGhcVersions = [ "925" ];
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
        # p.kubernetes-client
        p.morpheus-graphql-client
        p.text-time
        p.distributed-static
        p.json-syntax
        p.cgroup-rts-threads
        p.ki-effectful
        p.servant-effectful
        p.xstatic-htmx
        p.xstatic-sweetalert2
        p.chart-svg
        p.json-syntax
        p.gerrit
        p.tasty-discover
        p.markdown-unlit
        p.string-qq
        p.yaml
        p.gloss
        p.ansi-terminal-game
      ]);
      ghc-static = pkgs.hspkgsMusl.ghcWithPackages (p: [ p.relude ]);
      all-pkgs = [
        ghc
        # pkgs.nixGL.auto.nixGLDefault
        # ghc-static
        pkgs.nixGLIntel
        pkgs.weeder
        pkgs.ormolu
        pkgs.fourmolu
        pkgs.hlint
        pkgs.hpack
        pkgs.apply-refact
        pkgs.hspkgs.hoogle
        pkgs.calligraphy
        pkgs.haskell-language-server
        pkgs.ghcid
      ];

      # cabal-src = pkgs.fetchFromGitHub {
      #   owner = "mpickering";
      #   repo = "cabal";
      #   rev = "8325f25a0e1d17f28b94149f35d46d21f0c1fab3";
      #   sha256 = "sha256-MnzozddcRSRHoaiVDMzach9tcQwU5IIvtrJkh5A8q5M=";
      # };
      cabal-src = pkgs.fetchFromGitHub {
        owner = "TristanCacqueray";
        repo = "cabal";
        rev = "8f59ddcdd501bebcf2e195538f036646671e6831";
        sha256 = "sha256-zVtrvmHQY2DIX+//32pDkWXKUaQV/1nL4Y+/29cRTO8=";
      };
      cabal-src2 = pkgs.fetchFromGitHub {
        owner = "TristanCacqueray";
        repo = "cabal";
        rev = "e70cec87ef91ac26a09a3e550465080085ca0118";
        sha256 = "sha256-DHSGk9haxAvZkMwF5kO/ljiPY51PlsOF7OvPy57iuag=";
      };
      cabal-src3 = pkgs.fetchFromGitHub {
        owner = "TristanCacqueray";
        repo = "cabal";
        rev = "d372cb586cdb336f321b882f544e650f8f03135c";
        sha256 = "sha256-79TbV5vL8lIqMD+SwBHNenX/VvKV9DqP/ylIm069cNY=";
      };
      hs-ed25519 = pkgs.fetchFromGitHub {
        owner = "TristanCacqueray";
        repo = "hs-ed25519";
        rev = "9e03cd34c076cb002fe655ee38c57acdfaf618e8";
        sha256 = "sha256-UXIBeQPsOJc3OF4SrOLbqmzCi3U4dYW6k9TS/GwzZRM=";
      };
      dec = pkgs.fetchFromGitHub {
        owner = "phadej";
        repo = "dec";
        rev = "4ef1126187f5dd705c95ea6495ad93453f0ac55b";
        sha256 = "sha256-yYrihdRzciCLQ46sQc1U0rcg48FKiGXPh7Ryb8FaJLg=";
      };
      indexed-traversable = pkgs.fetchFromGitHub {
        owner = "haskellari";
        repo = "indexed-traversable";
        rev = "b4c2fd68333628a538f0d622069e1d4f25a26109";
        sha256 = "sha256-opeAGBm9CTBZ314xFmhnH2/JLk2+/LMUVLCvDPYINlY=";
      };
      these = pkgs.fetchFromGitHub {
        owner = "haskellari";
        repo = "these";
        rev = "7093bb26d6420a332150d58032de4dec70e7e1c8";
        sha256 = "sha256-XziV8GhmS3KEUGkHpvQa4ahBdNTk1wnloSfiOZQduac=";
      };
      some = pkgs.fetchFromGitHub {
        owner = "haskellari";
        repo = "some";
        rev = "c9872cfe7753b54d97f65532c0d2190edd32d2b8";
        sha256 = "sha256-1xCbTuqWRHLS6boCtDXu7oR6Ffp6af2mud3vC1Wwycc=";
      };
      OneTuple = pkgs.fetchFromGitHub {
        owner = "haskellari";
        repo = "OneTuple";
        rev = "76381386927716343b97614adb0061e3e1d7a92b";
        sha256 = "sha256-6v2jXz0Q6eBu6Qbyr/yXQHswuCtrl5lPpie9fABtXyA=";
      };
      tar = pkgs.fetchFromGitHub {
        owner = "haskell";
        repo = "tar";
        rev = "dc064da2e36972ab1e2dd737c2359d094cca9842";
        sha256 = "sha256-Go817rt/zeXM9e25DZWifHcjAN/q/2IFsnS4BeuF278=";
      };
      hashable = pkgs.fetchFromGitHub {
        owner = "haskell-unordered-containers";
        repo = "hashable";
        rev = "91caba893bf5d56b15941cc78ce865e934fee14b";
        sha256 = "sha256-rEB25/oefe7UtTSMRvwl+RjJX5fM1mczWug8EZL41W8=";
      };
      data-fix = pkgs.fetchFromGitHub {
        owner = "spell-music";
        repo = "data-fix";
        rev = "5c5d44404d6fbeb846227405d5e7470f889212c2";
        sha256 = "sha256-e4YPfcs09+O0kKAWPGJnCUUR9l7oB3m0DHmwKAZLXiU=";
      };
      cryptohash-sha256 = pkgs.fetchFromGitHub {
        owner = "TristanCacqueray";
        repo = "cryptohash-sha256";
        rev = "fa0f68cd936cb30e15d2ace61ad0f9c88818e04e";
        sha256 = "sha256-jBIbnlG/4Lv/io3Kp27y+ALMHmGz2YFzD2TxJ33Xk2s=";
      };
      singleton-bool = pkgs.fetchFromGitHub {
        owner = "TristanCacqueray";
        repo = "singleton-bool";
        rev = "c2ba8f9bd4c6653339b978399dcaadee95600a6d";
        sha256 = "sha256-irJXms0PT2yjGkVIp5FP9Fzl/ic+U4CxOUtds23/yVU=";
      };
      HTTP = pkgs.fetchFromGitHub {
        owner = "TristanCacqueray";
        repo = "HTTP";
        rev = "1ce377537bc8454c31bbd918d7610d09f6b30c78";
        sha256 = "sha256-VJj+LHw6K86rz7CFtc4FjlgrtDLnra2EXGu0dqdnumQ=";
      };
      generic-deriving = pkgs.fetchFromGitHub {
        owner = "dreixel";
        repo = "generic-deriving";
        rev = "5bfe558c6acb4a7a2a0c2d9652209152ad928a8b";
        sha256 = "sha256-+3We33sDvD0P/vsLjDMOFSkXwddmYK4GuUfag7uWN9o=";
      };
      lukko = pkgs.fetchFromGitHub {
        owner = "TristanCacqueray";
        repo = "lukko";
        rev = "a929e08e3bd7bb3076cdd717e79154c786569698";
        sha256 = "sha256-EAwmepPh+n02ux8/upHjNF9VsT9ZzGYNJjA/mMFLWVo=";
      };
      ChasingBottoms = pkgs.fetchFromGitHub {
        owner = "TristanCacqueray";
        repo = "ChasingBottoms";
        rev = "6d3fa706a72e0cdd3c75b6e4d61484c08124ff99";
        sha256 = "sha256-EAwmepPh+n02ux8/upHjNF9VsT3ZzGYNJjA/mMFLWVo=";
      };
      bifunctors = pkgs.fetchFromGitHub {
        owner = "ekmett";
        repo = "bifunctors";
        rev = "bbd72f3367dded9a5f491f6bbb755d93fc752234";
        sha256 = "sha256-wQ5lSCcXyE1FXcCtfk20Oo4Ok0KYa5qvUYwNPsY+/A0=";
      };
      semigroupoids = pkgs.fetchFromGitHub {
        owner = "ekmett";
        repo = "semigroupoids";
        rev = "54c5e091cfaba11d55b354d0bf52f8494f77b9f2";
        sha256 = "sha256-0CuTsCP4yc/crz+r4sGLSrA9C7AW2Tt5o9/TvzbzS0w=";
      };
      hackage-security = pkgs.fetchFromGitHub {
        owner = "TristanCacqueray";
        repo = "hackage-security";
        rev = "b6d051bb8a8c517db788febf6b70af7e260d0083";
        sha256 = "sha256-QzMBtXqNsXobJBr10LVDXYehmnBrCCCUGJbnoNmj5ls=";
      };
      cabalSet = pkgs.haskell.packages.ghc961.extend (hpFinal: hpPrev:
        let
          mk-cabal-lib = name:
            hpPrev.callCabal2nix name "${cabal-src}/${name}" { };
        in {
          foldable1-classes-compat =
            pkgs.haskell.lib.dontCheck hpPrev.foldable1-classes-compat;

          boring = pkgs.haskell.lib.overrideCabal hpPrev.boring {
            version = "0.2.1";
            revision = "0";
            editedCabalFile =
              "sha256-jHmoqq71YvLSCtpGLhSY7ZYqenYHKs0qBt22HSMinuQ=";
            sha256 = "sha256-sf/d8PnVCsh0KqAbJwhW1Xk3zI96rng+O186vueqMVQ=";
          };
          th-compat = pkgs.haskell.lib.overrideCabal hpPrev.th-compat {
            version = "0.1.4";
            revision = "2";
            editedCabalFile =
              "sha256-5a58CD7zoiJIVY+EUWabscVeqAkPWQi4a5AzdDwWFzA=";
          };
          text-short = pkgs.haskell.lib.overrideCabal hpPrev.text-short {
            revision = "2";
            editedCabalFile =
              "sha256-jHmoqq91YvLSCtpGLhSY7ZYqenYHKs0qBt22HSMinuQ=";
          };

          Cabal-syntax = mk-cabal-lib "Cabal-syntax";
          Cabal = mk-cabal-lib "Cabal";
          Cabal-QuickCheck = mk-cabal-lib "Cabal-QuickCheck";
          Cabal-tree-diff = mk-cabal-lib "Cabal-tree-diff";
          Cabal-described = mk-cabal-lib "Cabal-described";
          cabal-install-solver = pkgs.haskell.lib.dontCheck
            (hpPrev.callCabal2nix "cabal-install-solver"
              "${cabal-src2}/cabal-install-solver" { });
          cabal-install = pkgs.haskell.lib.dontCheck
            (hpPrev.callCabal2nix "cabal-install" "${cabal-src3}/cabal-install"
              { });
          ed25519 = pkgs.haskell.lib.dontCheck
            (hpPrev.callCabal2nix "ed25519" hs-ed25519 { });
          indexed-traversable = hpPrev.callCabal2nix "indexed-traversable"
            "${indexed-traversable}/indexed-traversable/" { };
          cryptohash-sha256 = pkgs.haskell.lib.dontCheck
            (pkgs.haskell.lib.overrideSrc hpPrev.cryptohash-sha256 {
              src = cryptohash-sha256;
            });
          generic-deriving = pkgs.haskell.lib.dontCheck
            (pkgs.haskell.lib.overrideSrc hpPrev.generic-deriving {
              src = generic-deriving;
            });

          semigroupoids = pkgs.haskell.lib.dontCheck
            (hpPrev.callCabal2nix "semigroupoids" semigroupoids { });

          indexed-traversable-instances =
            pkgs.haskell.lib.dontCheck hpPrev.indexed-traversable-instances;
          semialign = pkgs.haskell.lib.dontCheck
            (hpPrev.callCabal2nix "semialign" "${these}/semialign" { });
          aeson = pkgs.haskell.lib.dontCheck hpPrev.aeson;
          bifunctors = pkgs.haskell.lib.dontCheck
            (hpPrev.callCabal2nix "bifunctors" bifunctors { });
          hackage-security = pkgs.haskell.lib.dontCheck
            (pkgs.haskell.lib.overrideSrc hpPrev.hackage-security {
              src = "${hackage-security}/hackage-security";
            });
          some = hpPrev.callCabal2nix "some" some { };
          HTTP = hpPrev.callCabal2nix "HTTP" HTTP { };
          dec = hpPrev.callCabal2nix "dec" dec { };
          singleton-bool = pkgs.haskell.lib.overrideSrc hpPrev.singleton-bool {
            src = singleton-bool;
          };
          lukko = pkgs.haskell.lib.overrideSrc hpPrev.lukko { src = lukko; };
          OneTuple = hpPrev.callCabal2nix "OneTuple" OneTuple { };
          hashable = hpPrev.callCabal2nix "hashable" hashable { };
          data-fix = hpPrev.callCabal2nix "data-fix" data-fix { };
          tar = pkgs.haskell.lib.overrideSrc hpPrev.tar { src = tar; };
          # doctests doesn't seem to pass.
          vector = pkgs.haskell.lib.dontCheck hpPrev.vector;
          primitive = pkgs.haskell.lib.dontCheck hpPrev.primitive_0_7_4_0;
          data-array-byte = pkgs.haskell.lib.dontCheck hpPrev.data-array-byte;
          tagged = hpPrev.tagged_0_8_7;
          async = pkgs.haskell.lib.overrideCabal hpPrev.async {
            revision = "3";
            editedCabalFile =
              "sha256-RjZ9wMgybcvre5PyALVnSRwvYCm8z4Iri7Ju5mA5fgg=";
          };
          scientific = pkgs.haskell.lib.overrideCabal hpPrev.scientific {
            revision = "5";
            editedCabalFile =
              "sha256-JtgQkQaWOjRTaAEQgUU9Je4d+mr64rH1e0JrS805LZE=";
          };
          time-compat = pkgs.haskell.lib.overrideCabal hpPrev.time-compat {
            revision = "5";
            editedCabalFile =
              "sha256-RjZ8wMgybcvre5PyALVnSRwvYCm8z4Iri7Ju5mA5fgg=";
          };
          uuid-types = pkgs.haskell.lib.overrideCabal hpPrev.uuid-types {
            revision = "4";
            editedCabalFile =
              "sha256-RjZ9wMgybcvre5PyALVnSRwvYCm8z4Iri7Ju5mA5fgg=";
          };
          ChasingBottoms = pkgs.haskell.lib.overrideSrc hpPrev.ChasingBottoms {
            src = ChasingBottoms;
          };
          doctest = pkgs.haskell.lib.overrideCabal hpPrev.doctest {
            version = "0.21.1";
            sha256 = "sha256-YzaqRXxUFWEVGxdozhrUKLyADcJ3vtAsr0KqaG5C9G0=";
          };
          # https://github.com/dreixel/syb/issues/40
          syb = pkgs.haskell.lib.dontCheck hpPrev.syb;
        });
      cabal-install-multi-repl = cabalSet.cabal-install;

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

      packages.x86_64-linux.cabal = cabal-install-multi-repl;

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
