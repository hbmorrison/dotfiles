-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

config.color_scheme = 'Solarized (light) (terminal.sexy)'
config.font = wezterm.font 'Fira Code'
config.font_size = 14
config.initial_rows = 28
config.initial_cols = 100
config.window_padding = {
  left = 2,
  right = 2,
  top = 2,
  bottom = 2
}
-- config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.exit_behavior = 'CloseOnCleanExit'

return config
