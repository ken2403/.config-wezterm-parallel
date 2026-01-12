local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- =============================================================================
-- 起動時に L字型3ペイン構成 + diffwatch自動起動
-- =============================================================================
wezterm.on("gui-startup", function(cmd)
  local tab, pane, window = mux.spawn_window(cmd or {})
  -- 左側にモニターペイン (25%)
  local monitor_pane = pane:split({ direction = "Left", size = 0.25 })
  -- 右側（AI）の下20%に人間用ペイン
  local human_pane = pane:split({ direction = "Bottom", size = 0.20 })
  -- モニターペインでdiffwatch起動
  monitor_pane:send_text("diffwatch\n")
  -- フォーカスをAIメインペインに戻す
  pane:activate()
end)

-- =============================================================================
-- フォント設定
-- =============================================================================
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 13
config.line_height = 1.05

-- =============================================================================
-- カラースキーム（Light Green Theme - 目に優しく見やすい）
-- =============================================================================
config.colors = {
  -- 基本色（わずかにグリーンがかった白背景）
  foreground = "#1f2328",
  background = "#f8faf8",  -- 薄くグリーンがかった白

  -- ANSI色（グリーン系をメインに）
  ansi = {
    "#1f2328",  -- black
    "#cf222e",  -- red (エラー用)
    "#116329",  -- green (メインカラー)
    "#7d5c00",  -- yellow (警告)
    "#0550ae",  -- blue (情報)
    "#8250df",  -- magenta
    "#1a7f37",  -- cyan (サブグリーン)
    "#6e7781",  -- white
  },
  brights = {
    "#57606a",  -- bright black
    "#a40e26",  -- bright red
    "#1a7f37",  -- bright green
    "#9a6700",  -- bright yellow
    "#0969da",  -- bright blue
    "#a475f9",  -- bright magenta
    "#2da44e",  -- bright cyan (アクセントグリーン)
    "#8c959f",  -- bright white
  },

  -- タブバーの色（グリーンアクセント）
  tab_bar = {
    background = "#f0f4f0",
    active_tab = {
      bg_color = "#dafbe1",  -- 薄いグリーン背景
      fg_color = "#116329",  -- グリーン文字
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = "#f0f4f0",
      fg_color = "#57606a",
    },
    inactive_tab_hover = {
      bg_color = "#e6f4e8",
      fg_color = "#116329",
    },
    new_tab = {
      bg_color = "#f0f4f0",
      fg_color = "#57606a",
    },
    new_tab_hover = {
      bg_color = "#e6f4e8",
      fg_color = "#116329",
    },
  },

  -- カーソル（グリーン）
  cursor_bg = "#1a7f37",
  cursor_fg = "#ffffff",
  cursor_border = "#1a7f37",

  -- 選択範囲（薄いグリーン）
  selection_bg = "#b4f1be",
  selection_fg = "#1f2328",

  -- 分割線（見やすく）
  split = "#8dc891",
}

-- 非アクティブペインの見た目
config.inactive_pane_hsb = {
  saturation = 0.85,
  brightness = 0.92,
}

-- =============================================================================
-- ウィンドウ設定
-- =============================================================================
config.window_background_opacity = 1.0
config.macos_window_background_blur = 0
config.window_padding = {
  left = 12,
  right = 12,
  top = 12,
  bottom = 12,
}
config.window_decorations = "RESIZE"
config.initial_cols = 160
config.initial_rows = 45

-- =============================================================================
-- タブバー設定
-- =============================================================================
config.use_fancy_tab_bar = true
config.window_frame = {
  font = wezterm.font("JetBrainsMono Nerd Font", { weight = "Medium" }),
  font_size = 12,
  active_titlebar_bg = "#f0f4f0",
  inactive_titlebar_bg = "#f0f4f0",
}
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 40

-- タブのタイトル（シンプルにディレクトリ名）
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local pane = tab.active_pane
  local cwd = pane.current_working_dir

  local title = ""

  if cwd then
    local path = cwd.file_path or ""
    title = path:match("([^/]+)/?$") or path
  else
    title = tab.active_pane.title
  end

  return {
    { Attribute = { Intensity = "Bold" } },
    { Text = " " .. (tab.tab_index + 1) .. ": " .. title .. " " },
  }
end)

-- =============================================================================
-- キーバインド
-- =============================================================================
config.keys = {
  -- タブ操作
  -- 新規タブ（L字型3ペイン構成 + diffwatch自動起動）
  {
    key = "t",
    mods = "CMD",
    action = wezterm.action_callback(function(window, pane)
      local tab, new_pane, _ = window:mux_window():spawn_tab({})
      -- 左側にモニターペイン (25%)
      local monitor_pane = new_pane:split({ direction = "Left", size = 0.25 })
      -- 右側（AI）の下20%に人間用ペイン
      local human_pane = new_pane:split({ direction = "Bottom", size = 0.20 })
      -- モニターペインでdiffwatch起動
      monitor_pane:send_text("diffwatch\n")
      -- フォーカスをAIメインペインに
      new_pane:activate()
    end),
  },

  -- シンプルな新規タブ（ペイン分割なし）
  {
    key = "t",
    mods = "CMD|SHIFT",
    action = act.SpawnTab("CurrentPaneDomain"),
  },

  { key = "w", mods = "CMD", action = act.CloseCurrentTab({ confirm = false }) },
  { key = "[", mods = "CMD|SHIFT", action = act.ActivateTabRelative(-1) },
  { key = "]", mods = "CMD|SHIFT", action = act.ActivateTabRelative(1) },

  -- タブの順番を入れ替え
  { key = "LeftArrow", mods = "CMD|OPT|SHIFT", action = act.MoveTabRelative(-1) },
  { key = "RightArrow", mods = "CMD|OPT|SHIFT", action = act.MoveTabRelative(1) },

  -- タブ番号で移動 (Cmd+1-9)
  { key = "1", mods = "CMD", action = act.ActivateTab(0) },
  { key = "2", mods = "CMD", action = act.ActivateTab(1) },
  { key = "3", mods = "CMD", action = act.ActivateTab(2) },
  { key = "4", mods = "CMD", action = act.ActivateTab(3) },
  { key = "5", mods = "CMD", action = act.ActivateTab(4) },
  { key = "6", mods = "CMD", action = act.ActivateTab(5) },
  { key = "7", mods = "CMD", action = act.ActivateTab(6) },
  { key = "8", mods = "CMD", action = act.ActivateTab(7) },
  { key = "9", mods = "CMD", action = act.ActivateTab(8) },

  -- ペイン分割
  { key = "d", mods = "CMD", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "d", mods = "CMD|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

  -- ペイン移動 (Cmd+Option+矢印)
  { key = "LeftArrow", mods = "CMD|OPT", action = act.ActivatePaneDirection("Left") },
  { key = "RightArrow", mods = "CMD|OPT", action = act.ActivatePaneDirection("Right") },
  { key = "UpArrow", mods = "CMD|OPT", action = act.ActivatePaneDirection("Up") },
  { key = "DownArrow", mods = "CMD|OPT", action = act.ActivatePaneDirection("Down") },

  -- ペイン移動 (Cmd+Option+hjkl) - Vim風
  { key = "h", mods = "CMD|OPT", action = act.ActivatePaneDirection("Left") },
  { key = "l", mods = "CMD|OPT", action = act.ActivatePaneDirection("Right") },
  { key = "k", mods = "CMD|OPT", action = act.ActivatePaneDirection("Up") },
  { key = "j", mods = "CMD|OPT", action = act.ActivatePaneDirection("Down") },

  -- ペイン番号で直接移動 (Cmd+Opt+1/2/3)
  { key = "1", mods = "CMD|OPT", action = act.ActivatePaneByIndex(0) },  -- AI Pane
  { key = "2", mods = "CMD|OPT", action = act.ActivatePaneByIndex(1) },  -- Monitor
  { key = "3", mods = "CMD|OPT", action = act.ActivatePaneByIndex(2) },  -- Human

  -- ペインサイズ調整
  { key = "LeftArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
  { key = "RightArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },
  { key = "UpArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Up", 3 }) },
  { key = "DownArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Down", 3 }) },

  -- ペインを閉じる
  { key = "w", mods = "CMD|SHIFT", action = act.CloseCurrentPane({ confirm = false }) },

  -- ペインズーム (トグル)
  { key = "z", mods = "CMD", action = act.TogglePaneZoomState },

  -- ペインを入れ替え
  { key = "0", mods = "CMD|OPT", action = act.PaneSelect({ mode = "SwapWithActive" }) },

  -- Quick Select (パス/URL等を選択)
  { key = " ", mods = "CMD|SHIFT", action = act.QuickSelect },

  -- 画面クリア
  { key = "k", mods = "CMD", action = act.ClearScrollback("ScrollbackAndViewport") },

  -- 検索
  { key = "f", mods = "CMD", action = act.Search({ CaseInSensitiveString = "" }) },

  -- コピーモード
  { key = "c", mods = "CMD|SHIFT", action = act.ActivateCopyMode },

  -- 設定リロード
  { key = "r", mods = "CMD|SHIFT", action = act.ReloadConfiguration },

  -- ランチャー（コマンドパレット風）
  { key = "p", mods = "CMD|SHIFT", action = act.ShowLauncher },
}

-- =============================================================================
-- マウス設定
-- =============================================================================
config.mouse_bindings = {
  -- 右クリックでペースト
  {
    event = { Down = { streak = 1, button = "Right" } },
    mods = "NONE",
    action = act.PasteFrom("Clipboard"),
  },
  -- Cmd+クリックでリンクを開く
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "CMD",
    action = act.OpenLinkAtMouseCursor,
  },
}

-- =============================================================================
-- Quick Select パターン
-- =============================================================================
config.quick_select_patterns = {
  -- ファイルパス
  "[\\w\\-\\./]+\\.[\\w]+",
  -- Git SHA
  "[0-9a-f]{7,40}",
  -- UUID
  "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}",
  -- ブランチ名 (feat/xxx, fix/xxx)
  "(feat|fix|task|chore|docs)/[\\w\\-/]+",
}

-- =============================================================================
-- その他
-- =============================================================================
config.scrollback_lines = 10000
config.enable_scroll_bar = false
config.audible_bell = "Disabled"
config.window_close_confirmation = "NeverPrompt"

-- 新規ペイン/タブは現在のディレクトリを継承
config.default_cwd = wezterm.home_dir

-- IME設定 (日本語入力)
config.use_ime = true
config.macos_forward_to_ime_modifier_mask = "SHIFT|CTRL"

return config
