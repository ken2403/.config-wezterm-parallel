# WezTerm Parallel Development Config

AI-Agent並列開発をサポートするWezTerm + zsh設定

> **Note**: macOS専用（WezTerm CLIパスが `/Applications/WezTerm.app/Contents/MacOS/wezterm` 前提）

## 特徴

- **4ペイン構成**: 起動時・新規タブ作成時に自動で4ペイン構成
- **二段階モニタリング**: ワーキング差分とブランチ差分を同時監視
- **ライトグリーンテーマ**: 目に優しく見やすいカラースキーム
- **Git Worktree統合**: タスクごとに独立したWorktreeを自動作成

## ペインレイアウト

```
┌─────────┬──────────────────────────────┐
│ WORKING │                              │
│(diffwatch) 🤖 AI PANE (80%)            │
├─────────┤  (Claude Code)               │
│ BRANCH  │                              │
│(branchdiff)─────────────────────────────┤
│         │  🔧 HUMAN (20%)              │
└─────────┴──────────────────────────────┘
    20%              80%
```

- **Working Monitor (左上 20%)**: ワーキングディレクトリの差分をツリー形式で自動監視
- **Branch Monitor (左下 20%)**: デフォルトブランチとの差分をツリー形式で自動監視
- **AI Pane (右上 80%)**: Claude Codeのメイン作業エリア
- **Human Pane (右下 20%)**: 手動コマンド実行用

## 構成

```
.config-wezterm-parallel/
├── wezterm/
│   └── wezterm.lua      # WezTerm設定（UI・色・ペイン構成）
├── zsh/
│   ├── parallel-dev.zsh # 並列開発コマンド群 + 色設定
│   └── .p10k.zsh        # Powerlevel10k設定
├── sheldon/
│   └── plugins.toml     # sheldonプラグイン設定
├── install.sh           # インストールスクリプト
└── README.md
```

## 前提条件

以下のツールがインストールされていること:

- [WezTerm](https://wezfurlong.org/wezterm/)
- [sheldon](https://github.com/rossmacarthur/sheldon) - プラグインマネージャ
- [fzf](https://github.com/junegunn/fzf) - ファジーファインダー
- [zoxide](https://github.com/ajeetdsouza/zoxide) - スマートcd
- [JetBrainsMono Nerd Font](https://www.nerdfonts.com/) - フォント

```bash
# Homebrew でインストール
brew install sheldon fzf zoxide
brew tap homebrew/cask-fonts
brew install --cask font-jetbrains-mono-nerd-font
```

## インストール

```bash
source ./install.sh
```

※ `source` で実行すると zshrc の再読み込みまで自動で行われます

## コマンド

| コマンド | 説明 |
|----------|------|
| `pdev <task>` | **Worktree作成** + 新タブ（4ペイン + 2モニター） |
| `pstatus` | 全Worktree状態確認 |
| `diffwatch [interval]` | ワーキング差分モニター（デフォルト2秒） |
| `branchdiff [interval]` | ブランチ差分モニター（デフォルト2秒） |
| `pmerge <task>` | タスクをマージ |
| `pclean [task]` | Worktree削除（fzf選択可） |
| `pdhelp` | 並列開発ヘルプ |
| `wh` | WezTermショートカットヘルプ |

## 使い方

### 新規タスクの開始（Worktree作成）

```bash
cd /path/to/git-repo
pdev feat-auth-login
# → ../repo-feat-auth-login に feat/auth/login ブランチ作成
# → 新タブで4ペイン構成が開く
# → 左上: ワーキング差分監視（diffwatch自動起動）
# → 左下: ブランチ差分監視（branchdiff自動起動）
```

### 既存Worktreeでの作業

```bash
# 既存のWorktreeディレクトリに移動済みの場合
# Cmd+T で4ペインの新規タブを開く（Worktree作成なし）
```

### ワークフロー例

1. **メインリポジトリで新規タスク開始**
   ```bash
   cd ~/projects/myapp          # メインリポジトリ
   pdev feat-user-profile       # Worktree + 新タブ作成
   ```

2. **既存タスクに戻る**
   ```bash
   cd ~/projects/myapp-feat-user-profile
   # Cmd+T で4ペイン構成の新規タブを開く
   ```

3. **シンプルなタブが必要な場合**
   - `Cmd+Shift+T` でペイン分割なしのタブを開く

## ショートカット

### タブ操作

| キー | 機能 |
|------|------|
| `Cmd+T` | 新タブ（4ペイン + 2モニター、現在のディレクトリで開く） |
| `Cmd+Shift+T` | シンプルな新タブ（分割なし、現在のディレクトリで開く） |
| `Cmd+W` | タブを閉じる |
| `Cmd+1-9` | タブ番号で移動 |
| `Cmd+Shift+[/]` | 前/次のタブ |
| `Cmd+Opt+Shift+←/→` | タブの順番を入れ替え |

### ペイン操作

| キー | 機能 |
|------|------|
| `Cmd+D` | 縦分割（左右に分ける） |
| `Cmd+Shift+D` | 横分割（上下に分ける） |
| `Cmd+Opt+矢印` | ペイン移動 |
| `Cmd+Opt+h/j/k/l` | Vim風ペイン移動 |
| `Cmd+Opt+1/2/3/4` | ペイン番号で直接移動（1:AI, 2:Working, 3:Branch, 4:Human） |
| `Cmd+Z` | ペインズーム（トグル） |
| `Cmd+Shift+W` | ペインを閉じる |
| `Cmd+Opt+0` | ペインを入れ替え |

### ペインサイズ調整

| キー | 機能 |
|------|------|
| `Cmd+Shift+←/→` | 左右にリサイズ |
| `Cmd+Shift+↑/↓` | 上下にリサイズ |

### その他

| キー | 機能 |
|------|------|
| `Cmd+Shift+Space` | Quick Select（パス/URL選択） |
| `Cmd+K` | 画面クリア |
| `Cmd+F` | 検索 |
| `Cmd+Shift+C` | コピーモード |
| `Cmd+Shift+R` | 設定リロード |
| `Cmd+Shift+P` | ランチャー |
| `Cmd+クリック` | リンクを開く |
| `右クリック` | ペースト |

## sheldonプラグイン

- powerlevel10k - プロンプトテーマ
- zsh-autosuggestions - コマンド候補表示
- zsh-syntax-highlighting - シンタックスハイライト
- zsh-completions - 補完強化
- zsh-abbr - 略語展開
