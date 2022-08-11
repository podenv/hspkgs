# hspkgs - an alternative haskell package set

The goal is to provide a reusable, bleeding edge, set of packages based on nixpkgs that works with the most recent ghc version.
Some packages may includes un-merged PR to make it work.
Feel free to add your own workarounds.

## Features

Libs:

- ghc-9.2.4
- relude-1.1.0.0
- monomer-1.4.1.0

Tools:

- doctest-0.20.0
- hpack-0.35.0 (for `language: GHC2021` attribute)
- ormolu-0.5.0.1
- fourmolu-0.8.0.0
- weeder-2.4.0
- calligraphy-0.1.3
- apply-refact-0.10.0.0

Helpers:

- mk-nixgl-command : run a program with nixGL
- mk-static-haskell : build a static binary with musl
- run-hoogle : a devshell with a `run` command to start the service

## Usage

Use the output `overlays.hspkgs`, for example in your flake:

```nix
{
  inputs = {
    nixpkgs.url =
      "github:NixOS/nixpkgs/d46be5b0e8baad998f8277e04370f0fd30dde11b";
    hspkgs.url = "github:podenv/hspkgs";
  };

  outputs = { self, nixpkgs, hspkgs }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ hspkgs.overlays.hspkgs ];
      };
      pkg = pkgs.hspkgs.callCabal2nix "my-project" self { };
      exe = pkgs.haskell.lib.justStaticExecutables pkg;
    in {
      packages."x86_64-linux".default = exe;
      devShell."x86_64-linux" = pkgs.hspkgs.shellFor {
        packages = p: [ pkg ];
        buildInputs = [
          pkgs.cabal-install
          pkgs.haskell-language-server
          pkgs.weeder
        ];
      };
    };
}
```

Follow the same upstream nixpkgs, see demo in [run-monomer](https://github.com/podenv/run-monomer):

```nix
{
  inputs = {
    hspkgs.url = "github:podenv/hspkgs/PIN_COMMIT";
  };

  outputs = { self, hspkgs }:
    let
      pkgs = hspkgs.pkgs;
      pkg = pkgs.hspkgs.callCabal2nix "my-project" self {};
    in {};
}
```

Speedup download by using the binary cache:

```ShellSession
nix build --option binary-caches "https://cache.nixos.org https://podenv.cachix.org" --option trusted-public-keys "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= podenv.cachix.org-1:FA80Dv5XSHxzMYOg1wEANhDN7h43nN8twBJiYNzcDGY="
```
