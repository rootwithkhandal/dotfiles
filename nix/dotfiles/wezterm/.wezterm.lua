    local wezterm = require 'wezterm'
    local act = wezterm.action
    local config = wezterm.config_builder()

    -- ── Font ────────────────────────────────────────────────────

    config.font = wezterm.font('JetBrains Mono', { weight = 'Regular' })
    config.font_size = 12.0
    config.adjust_window_size_when_changing_font_size = false
    config.line_height = 1.1
    config.cell_width = 1.0
    config.freetype_load_flags = 'NO_HINTING'

    -- ── Color scheme ────────────────────────────────────────────

    config.color_scheme = 'Catppuccin Mocha'

    -- ── Window ──────────────────────────────────────────────────
    config.window_decorations = 'RESIZE'
    config.window_background_opacity = 0.95
    config.win32_system_backdrop = 'Acrylic'
    config.window_padding = {
        left   = 12,
        right  = 12,
        top    = 8,
        bottom = 8,
    }
    config.initial_cols = 120
    config.initial_rows = 32
    config.window_close_confirmation = 'AlwaysPrompt'

    -- ── Tab bar ─────────────────────────────────────────────────

    config.enable_tab_bar = true
    config.use_fancy_tab_bar = false
    config.hide_tab_bar_if_only_one_tab = true
    config.tab_bar_at_bottom = true
    config.show_new_tab_button_in_tab_bar = false
    config.tab_max_width = 32

    -- ── Cursor ──────────────────────────────────────────────────

    config.default_cursor_style = 'BlinkingBar'
    config.cursor_blink_rate = 500
    config.cursor_blink_ease_in = 'EaseOut'
    config.cursor_blink_ease_out = 'EaseOut'

    -- ── Scrollback ──────────────────────────────────────────────

    config.scrollback_lines = 10000
    config.enable_scroll_bar = false

    -- ── Bell ────────────────────────────────────────────────────

    config.audible_bell = 'Disabled'
    config.visual_bell = {
        fade_in_function = 'EaseIn',
        fade_in_duration_ms = 75,
        fade_out_function = 'EaseOut',
        fade_out_duration_ms = 75,
        target = 'CursorColor',
    }

    -- ── Misc ────────────────────────────────────────────────────

    config.check_for_updates = false
    config.automatically_reload_config = true
    config.status_update_interval = 1000
    config.hyperlink_rules = wezterm.default_hyperlink_rules()

    -- ── Shell ───────────────────────────────────────────────────

    -- Uncomment one of these to set a default shell:
    -- config.default_domain = 'WSL:kali-linux'
    -- config.default_prog = { 'wsl', '-d', 'kali-linux', '/bin/bash' }
    -- config.default_prog = { 'pwsh.exe', '-NoLogo' }

    -- ── Keybindings ─────────────────────────────────────────────

    config.keys = {
        -- Pane splitting
        { key = 'h',          mods = 'ALT|SHIFT',    action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
        { key = 'v',          mods = 'ALT|SHIFT',    action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
        { key = 'w',          mods = 'CTRL|SHIFT',    action = act.CloseCurrentPane { confirm = true } },

        -- Pane navigation
        { key = 'j',  mods = 'ALT',           action = act.ActivatePaneDirection 'Left' },
        { key = 'l', mods = 'ALT',           action = act.ActivatePaneDirection 'Right' },
        { key = 'i',    mods = 'ALT',           action = act.ActivatePaneDirection 'Up' },
        { key = 'k',  mods = 'ALT',           action = act.ActivatePaneDirection 'Down' },

        -- Pane resizing
        { key = 'j',  mods = 'ALT|SHIFT',     action = act.AdjustPaneSize { 'Left', 3 } },
        { key = 'l', mods = 'ALT|SHIFT',     action = act.AdjustPaneSize { 'Right', 3 } },
        { key = 'i',    mods = 'ALT|SHIFT',     action = act.AdjustPaneSize { 'Up', 3 } },
        { key = 'k',  mods = 'ALT|SHIFT',     action = act.AdjustPaneSize { 'Down', 3 } },

        -- Pane zoom
        { key = 'Enter',      mods = 'CTRL|SHIFT',    action = act.TogglePaneZoomState },

        -- Tab management
        { key = 't',          mods = 'CTRL|SHIFT',    action = act.SpawnTab 'CurrentPaneDomain' },
        { key = 'Tab',        mods = 'CTRL',           action = act.ActivateTabRelative(1) },
        { key = 'Tab',        mods = 'CTRL|SHIFT',    action = act.ActivateTabRelative(-1) },

        -- Direct tab switching (Alt+1..5)
        { key = '1',          mods = 'ALT',            action = act.ActivateTab(0) },
        { key = '2',          mods = 'ALT',            action = act.ActivateTab(1) },
        { key = '3',          mods = 'ALT',            action = act.ActivateTab(2) },
        { key = '4',          mods = 'ALT',            action = act.ActivateTab(3) },
        { key = '5',          mods = 'ALT',            action = act.ActivateTab(4) },

        -- Font size
        { key = '+',          mods = 'CTRL|SHIFT',    action = act.IncreaseFontSize },
        { key = '-',          mods = 'CTRL',           action = act.DecreaseFontSize },
        { key = '0',          mods = 'CTRL',           action = act.ResetFontSize },

        -- Clipboard
        { key = 'c',          mods = 'CTRL|SHIFT',    action = act.CopyTo 'Clipboard' },
        { key = 'v',          mods = 'CTRL|SHIFT',    action = act.PasteFrom 'Clipboard' },

        -- Utilities
        { key = 'f',          mods = 'CTRL|SHIFT',    action = act.Search 'CurrentSelectionOrEmptyString' },
        { key = 'p',          mods = 'CTRL|SHIFT',    action = act.ActivateCommandPalette },
        { key = 'l',          mods = 'CTRL|SHIFT',    action = act.ShowDebugOverlay },
        { key = 'q',          mods = 'CTRL',           action = act.ToggleFullScreen },
        { key = '\'',         mods = 'CTRL',           action = act.ClearScrollback 'ScrollbackAndViewport' },
        { key = 'Enter',      mods = 'ALT',            action = act.ToggleFullScreen },
    }

    -- ── Mouse bindings ──────────────────────────────────────────

    config.mouse_bindings = {
        -- Ctrl-click opens hyperlinks
        {
            event = { Up = { streak = 1, button = 'Left' } },
            mods = 'CTRL',
            action = act.OpenLinkAtMouseCursor,
        },
    }

    return config
