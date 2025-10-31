# Workaround: Build mise with Rust 1.89 in Nix (__SYSTEM__)

Problem:
- Some Rust binaries built via Nix on __SYSTEM__ fail HTTPS operations with `hyper` (error: "invalid HTTP version parsed").
- `mise` installed from Nix hits this when requesting `https://mise-versions.jdx.dev` and `https://nodejs.org`.

Solution:
- Build `mise` using Rust 1.89 via `rust-overlay`, avoiding the linker issue.

## Before
- `mise` from stable `nixpkgs`.
- HTTPS requests fail with `invalid HTTP version parsed`.

## After
- `mise` is built with `rustc`/`cargo` 1.89.0 (via `rust-overlay`).
- HTTPS requests succeed.

## Changes

1) `flake.nix` — added input:
```nix
rust-overlay = {
  url = "github:oxalica/rust-overlay";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

2) New module: `darwin/mise-rust189.nix`
```nix
{ inputs, pkgs, system, ... }:
{
  nixpkgs.overlays = [
    (import inputs.rust-overlay)
    (final: prev: {
      mise = prev.mise.override {
        rustPlatform = prev.rustPlatform.override {
          rustc = final.rust-bin.stable."1.89.0".rustc;
          cargo = final.rust-bin.stable."1.89.0".cargo;
        };
      };
    })
  ];

  environment.systemPackages = [
    pkgs.mise
  ];
}
```

3) `flake.nix` — included the module:
```nix
modules = [
  ...
  ./darwin/mise-rust189.nix
];
```

4) Ensure no duplicates:
- Do not install `mise` via Homebrew.
- If installed via `nix-env`, remove: `nix-env -e mise`.

## Apply
```bash
darwin-rebuild switch --flake ~/.config/nix#__USERNAME__-__SYSTEM__
```

## Verify
```bash
which mise
mise --version
mise use --global --verbose node@lts
```

## Rollback (remove workaround)
Once nixpkgs compiles `mise` with a fixed toolchain by default:
1) Remove `./darwin/mise-rust189.nix` from `modules` in `flake.nix`.
2) Optionally delete `darwin/mise-rust189.nix`.
3) Remove `rust-overlay` from `inputs` if not needed elsewhere.
4) Rebuild:
```bash
darwin-rebuild switch --flake ~/.config/nix#__USERNAME__-__SYSTEM__
```
5) Verify again:
```bash
mise --version
mise use --global --verbose node@lts
```

Notes:
- If your nixpkgs does not accept `rustPlatform` override on `mise`, use an `overrideAttrs` with `buildRustPackage` and `rust-bin.stable."1.89.0"`.
- Alternative: pull only `mise` from `nixpkgs-unstable` while keeping the rest on stable.
