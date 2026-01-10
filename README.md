# WezTerm Parallel Development Config

AI-Agent並列開発をサポートするWezTerm + zsh設定

## 構成

```
.config-wezterm-parallel/
├── wezterm/
│   └── wezterm.lua      # WezTerm設定（UI・色・ペイン構成）
├── zsh/
│   └── parallel-dev.zsh # 並列開発コマンド群
├── zshrc-snippet.zsh    # zshrcに追加する内容
├── install.sh           # インストールスクリプト
└── README.md
```

## インストール

```bash
chmod +x install.sh
./install.sh
```

## zshrcに追加する内容

```zsh
# PATHに追加（path配列内）
/Applications/WezTerm.app/Contents/MacOS(N-/)

# Parallel Development Commands
source ~/.config/zsh/parallel-dev.zsh
```

## コマンド

| コマンド | 説明 |
|----------|------|
| `pdev <task>` | 並列開発タブ作成 |
| `pstatus` | 全Worktree状態確認 |
| `monitor` | 差分モニター |
| `pmerge <task>` | マージ |
| `pclean` | Worktree削除 |
| `pdhelp` | ヘルプ |

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
