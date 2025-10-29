{ ... }:
{
  programs = {
    wezterm = {
      enable = false;
      extraConfig = ''
        -- Pull in the wezterm API
        local wezterm = require("wezterm")

        -- This will hold the configuration.
        local config = wezterm.config_builder()

        -- Appearance
        config.color_scheme = "Catppuccin Mocha"
        config.hide_tab_bar_if_only_one_tab = true
        config.font = wezterm.font("Iosevka Nerd Font")
        config.font_size = 13.0

        config.initial_cols = 200
        config.initial_rows = 35

        -- https://github.com/wez/wezterm/issues/5990
        config.front_end = "WebGpu"

        -- and finally, return the configuration to wezterm
        return config
      '';
    };

  };
}
