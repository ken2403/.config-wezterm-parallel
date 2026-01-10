# WezTerm Parallel Development Config

AI-Agent並列開発をサポートするWezTerm + zsh設定

> **Note**: macOS専用（WezTerm CLIパスが `/Applications/WezTerm.app/Contents/MacOS/wezterm` 前提）

## 構成

```
.config-wezterm-parallel/
├── wezterm/
│   └── wezterm.lua      # WezTerm設定（UI・色・ペイン構成）
├── zsh/
│   └── parallel-dev.zsh # 並列開発コマンド群 + 色設定 + ヘルプ
├── sheldon/
│   └── plugins.toml     # sheldonプラグイン設定
├── install.sh           # インストールスクリプト
└── README.md
```

## インストール

```bash
source ./install.sh
```

※ `source` で実行すると zshrc の再読み込みまで自動で行われます

## コマンド

| コマンド | 説明 |
|----------|------|
| `pdev <task>` | 並列開発タブ作成 |
| `pstatus` | 全Worktree状態確認 |
| `monitor` | 差分モニター |
| `pmerge <task>` | マージ |
| `pclean` | Worktree削除 |
| `pdhelp` | 並列開発ヘルプ |
| `wh` | WezTermショートカットヘルプ |

## 使い方

```bash
cd /path/to/git-repo
pdev feat-auth-login
# → ../repo-feat-auth-login に feat/auth/login ブランチ作成
# → 新タブで3ペイン構成が開く
```

## ショートカット

| キー | 機能 |
|------|------|
| `Cmd+T` | 新タブ（3ペイン） |
| `Cmd+Opt+1/2/3` | ペイン切り替え |
| `Cmd+Opt+h/j/k/l` | Vim風ペイン移動 |
| `Cmd+Z` | ペインズーム |
