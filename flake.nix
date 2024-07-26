# When adding override:
# - Add them to the ghc devShell or the all-pkgs list
# - Run `nix run | nix shell nixpkgs#cachix --command cachix push podenv`
{
  description = "hspkgs";
  nixConfig.bash-prompt = "[nix(hspkgs)] ";

  inputs = {
    nixpkgs.url =
      "github:NixOS/nixpkgs/b79cc961fe98b158ea051ae3c71616872ffe8212";
  };

  outputs = { self, nixpkgs }:
    let
      # Get nixGL to run graphic application outside of nixos
      nixGLSrc = pkgs.fetchFromGitHub {
        owner = "guibou";
        repo = "nixGL";
        rev = "d709a8abcde5b01db76ca794280745a43c8662be";
        sha256 = "sha256-V1o2bCZdeYKP/0zgVp4EN0KUjMItAMk6J7SvCXUI5IU=";
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
        rev = "c3b43af72dc221b8120f7863ac83ebe2e12e5cda";
        sha256 = "sha256-v8cazn10BGukJIH1JoWhs20bXFtlKO4P21ACZ+l9qqg=";
      };
      servant-effectful = pkgs.fetchFromGitHub {
        owner = "Kleidukos";
        repo = "servant-effectful";
        rev = "cec4d5483ef461bc27c8a9a707ce7b7e4e14d110";
        sha256 = "sha256-UUNymCKASnpi6fh26Y5GQD3ufjkY7vbVqWwh75GcnU4=";
      };

      # https://github.com/ndmitchell/record-dot-preprocessor/pull/59
      large-records = pkgs.fetchFromGitHub {
        owner = "TristanCacqueray";
        repo = "large-records";
        rev = "5bcb0eb844f5b5affdd102ebcf3e34e45ac96ed8";
        sha256 = "sha256-W6Xh6aVOsx9rgM6IVin6w7Z3e9yUESSaxfejkyU0ekY=";
      };

      haskellExtend = hpFinal: hpPrev:
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

          # https://github.com/fakedata-haskell/fakedata/issues/51
          fakedata = pkgs.haskell.lib.dontCheck hpPrev.fakedata;

          # json-syntax test needs old tasty
          json-syntax = pkgs.haskell.lib.doJailbreak (pkgs.haskell.lib.dontCheck
            (pkgs.haskell.lib.overrideCabal hpPrev.json-syntax {
              broken = false;
            }));

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
          xstatic-quill = mk-xstatic-lib "xstatic-quill";
          xstatic-quill-cursors = mk-xstatic-lib "xstatic-quill-cursors";
          xstatic-otjs = mk-xstatic-lib "xstatic-otjs";

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

      compilerVersion = "964";
      compiler = "ghc${compilerVersion}";

      overlay = final: prev:
        let
          mk-exe = prev.haskell.lib.justStaticExecutables;
          hspkgs = prev.haskell.packages.${compiler}.extend haskellExtend;
          hls = prev.haskell-language-server.override {
            supportedGhcVersions = [ compilerVersion ];
          };
          nixGL = import nixGLSrc { pkgs = prev; };
        in {
          haskellExtend = haskellExtend;
          hspkgs = hspkgs;
          haskell-language-server = hls;
          hlint = mk-exe hspkgs.hlint;
          weeder = mk-exe hspkgs.weeder;
          ormolu = mk-exe hspkgs.ormolu;
          fourmolu = mk-exe hspkgs.fourmolu;
          eventlog2html = mk-exe hspkgs.eventlog2html;
          profiteur = mk-exe hspkgs.profiteur;
          calligraphy = mk-exe hspkgs.calligraphy;
          apply-refact = mk-exe hspkgs.apply-refact;
          tasty-discover = mk-exe hspkgs.tasty-discover;
          nixfmt = mk-exe hspkgs.nixfmt;
          cabal-fmt = mk-exe hspkgs.cabal-fmt;
          doctest = mk-exe hspkgs.doctest;
          # replace the global cabal-install by the one provided by the right compiler set
          cabal-install = prev.haskell.packages.${compiler}.cabal-install;
          # cabal-plan = mk-exe hspkgs.cabal-plan;

          hspkgsMusl =
            prev.pkgsMusl.haskell.packages.${compiler}.extend haskellExtend;

          roboto_font =
            "${prev.roboto}/share/fonts/truetype/Roboto-Regular.ttf";
          nixVulkanIntel = nixGL.nixVulkanIntel;
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
        packages = p: [ p.gerrit ];
        buildInputs = [ pkgs.ghcid pkgs.cabal-install ];
      };
    };
}
