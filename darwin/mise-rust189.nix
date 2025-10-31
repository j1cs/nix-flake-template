{
  inputs,
  pkgs,
  system,
  ...
}:
{
  nixpkgs.overlays = [
    (import inputs.rust-overlay)
    (
      final: prev:
      let
        toolchain189 = final.rust-bin.stable."1.89.0".default;
        rustPlatform189 = prev.makeRustPlatform {
          cargo = toolchain189;
          rustc = toolchain189;
        };
      in
      {
        mise = prev.mise.override {
          rustPlatform = rustPlatform189;
        };
      }
    )
  ];

  environment.systemPackages = [
    pkgs.mise
  ];
}
