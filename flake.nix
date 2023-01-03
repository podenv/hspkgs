# When adding override:
# - Add them to the ghc devShell or the all-pkgs list
# - Run `nix run | nix shell nixpkgs#cachix --command cachix push podenv`
{
  description = "hspkgs";
  nixConfig.bash-prompt = "[nix(hspkgs)] ";

  inputs = {
    nixpkgs.url =
      "github:NixOS/nixpkgs/3665c429d349fbda46b0651e554cca8434452748";
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

      # Need latest servant to build with ghc-9.2 base and lens-5.2
      servant = pkgs.fetchFromGitHub {
        owner = "haskell-servant";
        repo = "servant";
        rev = "a22600979a747ee201b8a1a2a84469285631682c";
        sha256 = "sha256-cA6v9Y/Qnc7tfGxl0oVycdYk5+eOXFVYUb44yBZQ5wg=";
      };

      # Need latest weeder for lens-5.2 support ( https://github.com/ocharles/weeder/pull/106 )
      weeder = pkgs.fetchFromGitHub {
        owner = "TristanCacqueray";
        repo = "weeder";
        rev = "177e9ccc144831233df3c90894c34bf523a79fc7";
        sha256 = "sha256-CSZXXxxJTiBWdqjJr37RmA8l/F9UuHxXJQ1sT0X4T5c=";
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
        rev = "12bff28548f838e898a46aeb5f50ad9091ff78e0";
        sha256 = "sha256-tbvjszYhbkNO5TSv6DjnKpsEQxChWIDANaLrtPTgtpw=";
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
            mk-servant-lib = name:
              hpPrev.callCabal2nix "sevant${name}" "${servant}/servant${name}"
              { };
            mk-servant-auth-lib = name:
              hpPrev.callCabal2nix "sevant-auth${name}"
              "${servant}/servant-auth/servant-auth${name}" { };
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

            # extra effectful package
            ki-effectful = pkgs.haskell.lib.dontCheck
              (hpPrev.callCabal2nix "ki-effectful" ki-effecful { });
            servant-effectful =
              hpPrev.callCabal2nix "servant-effectful" servant-effectful { };

            # servant = mk-servant-lib "";
            # servant-foreign = mk-servant-lib "-foreign";
            # servant-server = mk-servant-lib "-server";
            # servant-auth = mk-servant-auth-lib "";
            # # servant-auth-server test hangs
            # servant-auth-server =
            #   pkgs.haskell.lib.dontCheck (mk-servant-auth-lib "-server");

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

            weeder = hpPrev.callCabal2nix "weeder" weeder { };
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
      ]);
      ghc-static = pkgs.hspkgsMusl.ghcWithPackages (p: [ p.relude ]);
      all-pkgs = [
        ghc
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
