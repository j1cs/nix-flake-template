_: {
  # Manage Ghostty configuration declaratively (Application Support)
  home.file."Library/Application Support/com.mitchellh.ghostty/config".text = ''
    theme = glats
    font-family = "CaskaydiaCove Nerd Font"
    font-feature = "liga"
    background-opacity = 0.7
    scrollback-limit = 4294967295
    window-padding-balance = true
    window-padding-color = extend
  '';

  # Custom Ghostty theme
  home.file.".config/ghostty/themes/glats".text = ''
    palette = 0=#0a0a0a
    palette = 1=#cc0403
    palette = 2=#19cb00
    palette = 3=#cecb00
    palette = 4=#0d73cc
    palette = 5=#cb1ed1
    palette = 6=#0dcdcd
    palette = 7=#d0d0d0
    palette = 8=#767676
    palette = 9=#f2201f
    palette = 10=#23fd00
    palette = 11=#fffd00
    palette = 12=#1a8fff
    palette = 13=#fd28ff
    palette = 14=#14ffff
    palette = 15=#ffffff
    background = 000000
    foreground = dddddd
    cursor-color = dddddd
    selection-background = 505050
  '';
}
