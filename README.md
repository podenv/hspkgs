# hspkgs - an alternative haskell package set

The goal is to provide a reusable, bleeding edge, set of packages based on nixpkgs that works with the most recent ghc version.
Some packages may includes un-merged PR to make it work.
Feel free to add your own workarounds.

## Features

Packages:

- ghc-9.6.2
- weeder
- calligraphy
- apply-refact
- kubernetes-client
- cabal-multi-repl (just the next cabal release)

Helpers:

- mk-nixgl-command : run a program with nixGL
- mk-static-haskell : build a static binary with musl
- run-hoogle : a devshell with a `run` command to start the service

## Usage

Starts a shell with a full development environment:

```ShellSession
$ nix develop gitub:podenv/devenv
```

Use the output `overlays.hspkgs`, for example in your flake:

```nix
{
  inputs = {
    nixpkgs.url =
      "github:NixOS/nixpkgs/0dcf2ad93d93d0cba20f8517689267abc33014a6";
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

## Setup nixGL for nvidia

Using the same nixpkgs pin, install the `nixVulkanNvidia-$VERSION` wrapper using:

```ShellSession
NIXPKGS_ALLOW_UNFREE=1 nix build --override-input nixpkgs  github:NixOS/nixpkgs/3665c429d349fbda46b0651e554cca8434452748 --impure github:guibou/nixGL#nixVulkanNvidia
```
