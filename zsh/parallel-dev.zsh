# =============================================================================
# Parallel Development Commands for AI-Agent Workflow
# =============================================================================

# -----------------------------------------------------------------------------
# sheldon - Plugin Manager (must be before color settings)
# -----------------------------------------------------------------------------
if command -v sheldon &> /dev/null; then
  eval "$(sheldon source)"
fi

# -----------------------------------------------------------------------------
# fzf - Fuzzy Finder
# -----------------------------------------------------------------------------
if command -v fzf &> /dev/null; then
  source <(fzf --zsh)
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
fi

# -----------------------------------------------------------------------------
# zoxide - Smarter cd
# -----------------------------------------------------------------------------
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

# -----------------------------------------------------------------------------
# 色定義 (ライトグリーン系)
# -----------------------------------------------------------------------------
readonly C_RESET='\033[0m'
readonly C_BOLD='\033[1m'
readonly C_DIM='\033[2m'

# メインカラー (グリーン系)
readonly C_GREEN='\033[38;2;22;99;41m'       # #116329
readonly C_LGREEN='\033[38;2;26;127;55m'     # #1a7f37
readonly C_BGREEN='\033[48;2;218;251;225m'   # #dafbe1 bg

# アクセントカラー
readonly C_BLUE='\033[38;2;9;105;218m'       # #0969da
readonly C_YELLOW='\033[38;2;154;103;0m'     # #9a6700
readonly C_RED='\033[38;2;207;34;46m'        # #cf222e
readonly C_GRAY='\033[38;2;110;119;129m'     # #6e7781

# 背景付き
readonly C_BG_GREEN='\033[48;2;218;251;225m' # 薄緑背景
readonly C_BG_YELLOW='\033[48;2;255;248;197m' # 薄黄背景
readonly C_BG_BLUE='\033[48;2;221;244;255m'  # 薄青背景
readonly C_BG_RED='\033[48;2;255;235;233m'   # 薄赤背景

# -----------------------------------------------------------------------------
# ユーティリティ関数
# -----------------------------------------------------------------------------

# task名(-区切り) → branch名(/区切り)
_task_to_branch() {
  echo "$1" | sed 's/-/\//g'
}

# branch名(/区切り) → task名(-区切り)
_branch_to_task() {
  echo "$1" | sed 's/\//-/g'
}

# Git root取得
_git_root() {
  git rev-parse --show-toplevel 2>/dev/null
}

# Worktree base directory (リポジトリの親ディレクトリ)
_worktree_base() {
  local root=$(_git_root)
  [[ -n "$root" ]] && dirname "$root"
}

# 罫線描画
_line() {
  local char="${1:-─}"
  local width="${2:-50}"
  printf '%*s' "$width" '' | tr ' ' "$char"
}

# ヘッダー表示
_header() {
  echo ""
  echo -e "${C_GREEN}${C_BOLD}$(_line '━' 55)${C_RESET}"
  echo -e "${C_GREEN}${C_BOLD}  $1${C_RESET}"
  echo -e "${C_GREEN}${C_BOLD}$(_line '━' 55)${C_RESET}"
}

# サブヘッダー
_subheader() {
  echo -e "${C_GRAY}$(_line '─' 55)${C_RESET}"
  echo -e "${C_BOLD}  $1${C_RESET}"
  echo -e "${C_GRAY}$(_line '─' 55)${C_RESET}"
}

# 成功メッセージ
_success() {
  echo -e "${C_GREEN}${C_BOLD}  ✓${C_RESET} $1"
}

# エラーメッセージ
_error() {
  echo -e "${C_RED}${C_BOLD}  ✗${C_RESET} $1" >&2
}

# 警告メッセージ
_warn() {
  echo -e "${C_YELLOW}${C_BOLD}  !${C_RESET} $1"
}

# 情報メッセージ
_info() {
  echo -e "${C_BLUE}  ▸${C_RESET} $1"
}

# statsの色付け（+は緑、-は赤）
_colorize_stats() {
  local stats="$1"
  if [[ -z "$stats" ]]; then
    echo ""
    return
  fi
  # +数字を緑、-数字を赤で色付け
  stats="${stats//+/\\033[32m+}"
  stats="${stats//-/\\033[31m-}"
  stats="${stats}\\033[0m"
  echo -e "$stats"
}

# デフォルトブランチを取得
_default_branch() {
  # リモートのHEADから取得を試みる
  local remote_head=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
  if [[ -n "$remote_head" ]]; then
    echo "$remote_head"
    return
  fi

  # よくあるデフォルトブランチ名をチェック
  for branch in main master dev develop; do
    if git show-ref --verify --quiet "refs/heads/${branch}" || \
       git show-ref --verify --quiet "refs/remotes/origin/${branch}"; then
      echo "$branch"
      return
    fi
  done

  # 見つからなければ現在のブランチ
  git branch --show-current
}

# -----------------------------------------------------------------------------
# pdev - 並列開発タブ作成
# -----------------------------------------------------------------------------
pdev() {
  local task_name="$1"
  local base_branch="${2:-$(_default_branch)}"

  if [[ -z "$task_name" ]]; then
    _error "Usage: pdev <task-name> [base-branch]"
    _info "Example: pdev feat-auth-login"
    _info "         → Creates ../feat-auth-login with branch feat/auth/login"
    _info "         Base branch auto-detected: $(_default_branch)"
    return 1
  fi

  local git_root=$(_git_root)
  if [[ -z "$git_root" ]]; then
    _error "Not in a git repository"
    return 1
  fi

  local repo_name=$(basename "$git_root")
  local worktree_base=$(_worktree_base)
  local worktree_path="${worktree_base}/${repo_name}-${task_name}"
  local branch_name=$(_task_to_branch "$task_name")

  _header "Creating Parallel Dev Environment"

  # 既存チェック
  if [[ -d "$worktree_path" ]]; then
    _warn "Worktree already exists: $worktree_path"
    _info "Switching to existing worktree..."
  else
    # Worktree作成
    _info "Task:     ${C_BOLD}${task_name}${C_RESET}"
    _info "Branch:   ${C_GREEN}${branch_name}${C_RESET}"
    _info "Path:     ${C_BLUE}${worktree_path}${C_RESET}"
    _info "Base:     ${base_branch}"
    echo ""

    # ブランチが既に存在するかチェック
    local result

    if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
      # ローカルブランチが存在
      _info "Branch exists, attaching to existing branch..."
      result=$(git worktree add "$worktree_path" "$branch_name" 2>&1)
    else
      # 新規ブランチ作成 - ベースブランチを解決
      local base_ref="$base_branch"

      # ローカルにベースブランチがなければリモートを使用
      if ! git show-ref --verify --quiet "refs/heads/${base_branch}"; then
        if git show-ref --verify --quiet "refs/remotes/origin/${base_branch}"; then
          base_ref="origin/${base_branch}"
          _info "Using remote branch: ${base_ref}"
        fi
      fi

      result=$(git worktree add -b "$branch_name" "$worktree_path" "$base_ref" 2>&1)
    fi

    if [[ $? -ne 0 ]]; then
      _error "Failed to create worktree"
      _error "$result"
      return 1
    fi

    _success "Worktree created"
  fi

  # WezTermで新タブを開く（3ペイン構成）
  local wezterm_cli="/Applications/WezTerm.app/Contents/MacOS/wezterm"

  if [[ -n "$WEZTERM_PANE" ]] && [[ -x "$wezterm_cli" ]]; then
    _info "Opening new tab with 3-pane layout..."

    # WezTerm CLIで新タブ作成（メインペイン）
    local main_pane_id
    main_pane_id=$("$wezterm_cli" cli spawn --cwd "$worktree_path" 2>/dev/null)

    if [[ -z "$main_pane_id" ]] || ! [[ "$main_pane_id" =~ ^[0-9]+$ ]]; then
      _error "Failed to create new tab (pane_id: ${main_pane_id:-empty})"
      _warn "Falling back to cd"
      cd "$worktree_path"
      return 0
    fi

    # CLIコマンド間に少し待機（pane IDが安定するまで）
    sleep 0.2

    # 左側にモニターペイン (20%)
    local monitor_top_id
    monitor_top_id=$("$wezterm_cli" cli split-pane --left --percent 20 --pane-id "$main_pane_id" --cwd "$worktree_path" 2>/dev/null)

    if [[ -z "$monitor_top_id" ]] || ! [[ "$monitor_top_id" =~ ^[0-9]+$ ]]; then
      _warn "Failed to create monitor pane, tab created without split"
      "$wezterm_cli" cli activate-pane --pane-id "$main_pane_id" 2>/dev/null
      _success "New tab created (single pane)"
      return 0
    fi

    sleep 0.1

    # モニターペインを上下に分割
    local monitor_bottom_id
    monitor_bottom_id=$("$wezterm_cli" cli split-pane --bottom --percent 50 --pane-id "$monitor_top_id" --cwd "$worktree_path" 2>/dev/null)

    sleep 0.1

    # AIペインの下に人間ペイン (20%)
    "$wezterm_cli" cli split-pane --bottom --percent 20 --pane-id "$main_pane_id" --cwd "$worktree_path" 2>/dev/null

    sleep 0.1

    # 上のモニターペインでdiffwatchコマンドを実行
    "$wezterm_cli" cli send-text --pane-id "$monitor_top_id" --no-paste "diffwatch"$'\n' 2>/dev/null

    sleep 0.1

    # 下のモニターペインでbranchdiffコマンドを実行
    "$wezterm_cli" cli send-text --pane-id "$monitor_bottom_id" --no-paste "branchdiff"$'\n' 2>/dev/null

    # メインペインにフォーカス
    "$wezterm_cli" cli activate-pane --pane-id "$main_pane_id" 2>/dev/null

    _success "New tab created"
    _info "Tab: ${repo_name}-${task_name}"
  else
    _warn "Not running in WezTerm, just cd to worktree"
    cd "$worktree_path"
  fi

  echo ""
  _success "Ready! Branch: ${C_GREEN}${branch_name}${C_RESET}"
}

# -----------------------------------------------------------------------------
# diffwatch - 差分モニター（Tree表示）
# -----------------------------------------------------------------------------
diffwatch() {
  local interval="${1:-2}"
  local prev_output=""

  while true; do
    # 現在の状態を取得
    local branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    local task=$(_branch_to_task "$branch")
    local modified=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    local staged=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    local untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

    # 現在の出力内容を生成（変数に保存）
    local current_output=""
    current_output+="${branch}|${modified}|${staged}|${untracked}"

    # 差分リストを取得して状態に追加
    current_output+="|"
    current_output+=$(git diff --name-status 2>/dev/null | sort)
    current_output+="|"
    current_output+=$(git diff --cached --name-status 2>/dev/null | sort)
    current_output+="|"
    current_output+=$(git ls-files --others --exclude-standard 2>/dev/null | sort)

    # 前回と同じなら再描画をスキップ
    if [[ "$current_output" == "$prev_output" ]]; then
      sleep "$interval"
      continue
    fi

    # 変更があった場合のみ再描画
    prev_output="$current_output"

    # カーソルをホームに移動して画面クリア
    printf '\033[H\033[J'

    # ヘッダー
    echo -e "${C_GREEN}${C_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
    echo -e "${C_GREEN}${C_BOLD}  📊 MONITOR │ ${branch}${C_RESET}"
    echo -e "${C_GREEN}${C_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
    echo ""

    # サマリー
    echo -e "  ${C_YELLOW}●${C_RESET} Modified:  ${C_BOLD}${modified}${C_RESET}"
    echo -e "  ${C_GREEN}◆${C_RESET} Staged:    ${C_BOLD}${staged}${C_RESET}"
    echo -e "  ${C_GRAY}?${C_RESET} Untracked: ${C_BOLD}${untracked}${C_RESET}"
    echo ""

    # ファイルツリー表示（tree風）
    echo -e "${C_GRAY}$(_line '─' 35)${C_RESET}"
    echo ""

    if [[ $modified -gt 0 ]] || [[ $staged -gt 0 ]] || [[ $untracked -gt 0 ]]; then
      # 変更があるファイルを収集
      local -A changed_files=()
      while IFS=$'\t' read -r change_type file_status filepath; do
        # パスの正規化（先頭の./を削除）
        filepath="${filepath#./}"
        [[ -n "$filepath" ]] && changed_files[$filepath]="${change_type}|${file_status}"
      done < <({
        git diff --name-status 2>/dev/null | awk '{print "modified\t" $1 "\t" $2}'
        git diff --cached --name-status 2>/dev/null | awk '{print "staged\t" $1 "\t" $2}'
        git ls-files --others --exclude-standard 2>/dev/null | awk '{print "untracked\tU\t" $0}'
      })

      # トップレベルの構造を取得（ディレクトリとファイル）
      local -a top_dirs=()
      local -a top_files=()

      # git ls-tree でトップレベルを取得
      while read -r line; do
        [[ -z "$line" ]] && continue
        type=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | awk '{print $4}')

        if [[ -n "$name" && "$type" == "tree" ]]; then
          top_dirs+=("$name")
        elif [[ -n "$name" && "$type" == "blob" ]]; then
          top_files+=("$name")
        fi
      done < <(git ls-tree HEAD 2>/dev/null)

      # 変更があるディレクトリを特定（untrackedディレクトリも追加）
      local -A dir_has_changes
      local -A seen_top_dirs
      local -A seen_top_files

      for dir in "${top_dirs[@]}"; do
        seen_top_dirs[$dir]=1
      done

      for file in "${top_files[@]}"; do
        seen_top_files[$file]=1
      done

      for filepath in "${(@k)changed_files}"; do
        if [[ "$filepath" == */* ]]; then
          # ディレクトリ内のファイル
          topdir=$(echo "$filepath" | cut -d'/' -f1)
          dir_has_changes[$topdir]=1
          # untrackedディレクトリがtop_dirsにない場合は追加
          if [[ -z "${seen_top_dirs[$topdir]}" ]]; then
            top_dirs+=("$topdir")
            seen_top_dirs[$topdir]=1
          fi
        else
          # ルートレベルのファイル（untrackedファイル含む）
          if [[ -z "${seen_top_files[$filepath]}" ]]; then
            top_files+=("$filepath")
            seen_top_files[$filepath]=1
          fi
        fi
      done

      echo "  ."

      # ディレクトリを表示（total_itemsはtop_files更新後に計算）
      local total_items=$((${#top_dirs[@]} + ${#top_files[@]}))
      local current=0

      for dir in "${top_dirs[@]}"; do
        current=$((current + 1))
        local is_last=0
        [[ $current -eq $total_items ]] && is_last=1

        if [[ -n "${dir_has_changes[$dir]}" ]]; then
          # 変更があるディレクトリは展開
          if [[ $is_last -eq 1 ]] && [[ ${#top_files[@]} -eq 0 ]]; then
            echo "  └─ ${dir}/"
            prefix="     "
          else
            echo "  ├─ ${dir}/"
            prefix="  │  "
          fi

          # ディレクトリ内の変更ファイルを表示
          local -a dir_changed_files=()
          for filepath in "${(@k)changed_files}"; do
            if [[ "$filepath" == "${dir}/"* ]]; then
              dir_changed_files+=("$filepath")
            fi
          done

          local file_count=${#dir_changed_files[@]}
          local file_idx=0
          for filepath in "${(@on)dir_changed_files[@]}"; do
            file_idx=$((file_idx + 1))
            local file_is_last=0
            [[ $file_idx -eq $file_count ]] && file_is_last=1

            filename=$(basename "$filepath")
            IFS='|' read -r change_type file_status <<< "${changed_files[$filepath]}"

            # Status icon and color
            if [[ "$change_type" == "staged" ]]; then
              icon="${C_GREEN}◆${C_RESET}"
              color="${C_GREEN}"
            elif [[ "$change_type" == "untracked" ]]; then
              icon="${C_GRAY}?${C_RESET}"
              color="${C_GRAY}"
            else
              icon="${C_YELLOW}●${C_RESET}"
              color="${C_YELLOW}"
            fi

            # Status label
            case "$file_status" in
              M) status_label="[mod]" ;;
              A) status_label="[add]" ;;
              D) status_label="[del]" ;;
              R*) status_label="[ren]" ;;
              U) status_label="[new]" ;;
              *) status_label="[${file_status}]" ;;
            esac

            # Get stats
            if [[ "$change_type" == "staged" ]]; then
              stats=$(git diff --cached --numstat "$filepath" 2>/dev/null | awk '{print "+"$1" -"$2}')
            elif [[ "$change_type" == "untracked" ]]; then
              stats=$(wc -l < "$filepath" 2>/dev/null | awk '{print "+"$1}')
            else
              stats=$(git diff --numstat "$filepath" 2>/dev/null | awk '{print "+"$1" -"$2}')
            fi
            stats=$(_colorize_stats "$stats")

            if [[ $file_is_last -eq 1 ]]; then
              echo -e "${prefix}└─ ${filename} ${icon} ${color}${status_label}${C_RESET} ${stats}"
            else
              echo -e "${prefix}├─ ${filename} ${icon} ${color}${status_label}${C_RESET} ${stats}"
            fi
          done
        else
          # 変更がないディレクトリは名前だけ
          if [[ $is_last -eq 1 ]] && [[ ${#top_files[@]} -eq 0 ]]; then
            echo "  └─ ${dir}/"
          else
            echo "  ├─ ${dir}/"
          fi
        fi
      done

      # トップレベルのファイルを表示
      for file in "${top_files[@]}"; do
        current=$((current + 1))
        local is_last=0
        [[ $current -eq $total_items ]] && is_last=1

        if [[ -n "${changed_files[$file]}" ]]; then
          # 変更があるファイルは詳細表示
          IFS='|' read -r change_type file_status <<< "${changed_files[$file]}"

          # Status icon and color
          if [[ "$change_type" == "staged" ]]; then
            icon="${C_GREEN}◆${C_RESET}"
            color="${C_GREEN}"
          elif [[ "$change_type" == "untracked" ]]; then
            icon="${C_GRAY}?${C_RESET}"
            color="${C_GRAY}"
          else
            icon="${C_YELLOW}●${C_RESET}"
            color="${C_YELLOW}"
          fi

          # Status label
          case "$file_status" in
            M) status_label="[mod]" ;;
            A) status_label="[add]" ;;
            D) status_label="[del]" ;;
            R*) status_label="[ren]" ;;
            U) status_label="[new]" ;;
            *) status_label="[${file_status}]" ;;
          esac

          # Get stats
          if [[ "$change_type" == "staged" ]]; then
            stats=$(git diff --cached --numstat "$file" 2>/dev/null | awk '{print "+"$1" -"$2}')
          elif [[ "$change_type" == "untracked" ]]; then
            stats=$(wc -l < "$file" 2>/dev/null | awk '{print "+"$1}')
          else
            stats=$(git diff --numstat "$file" 2>/dev/null | awk '{print "+"$1" -"$2}')
          fi
          stats=$(_colorize_stats "$stats")

          if [[ $is_last -eq 1 ]]; then
            echo -e "  └─ ${file} ${icon} ${color}${status_label}${C_RESET} ${stats}"
          else
            echo -e "  ├─ ${file} ${icon} ${color}${status_label}${C_RESET} ${stats}"
          fi
        else
          # 変更がないファイルは名前だけ
          if [[ $is_last -eq 1 ]]; then
            echo "  └─ ${file}"
          else
            echo "  ├─ ${file}"
          fi
        fi
      done

      echo ""
    else
      # 差分がない場合でもroot構造を表示
      local -a top_dirs=()
      local -a top_files=()

      while read -r line; do
        type=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | awk '{print $4}')
        if [[ "$type" == "tree" ]]; then
          top_dirs+=("$name")
        elif [[ "$type" == "blob" ]]; then
          top_files+=("$name")
        fi
      done < <(git ls-tree HEAD 2>/dev/null)

      echo "  ."
      local total_items=$((${#top_dirs[@]} + ${#top_files[@]}))
      local current=0

      for dir in "${top_dirs[@]}"; do
        current=$((current + 1))
        if [[ $current -eq $total_items ]]; then
          echo "  └─ ${dir}/"
        else
          echo "  ├─ ${dir}/"
        fi
      done

      for file in "${top_files[@]}"; do
        current=$((current + 1))
        if [[ $current -eq $total_items ]]; then
          echo "  └─ ${file}"
        else
          echo "  ├─ ${file}"
        fi
      done

      echo ""
      echo -e "  ${C_GRAY}No changes${C_RESET}"
      echo ""
    fi

    # 合計差分（色付き）
    local total_stats=$(git diff --stat 2>/dev/null | tail -1)
    if [[ -n "$total_stats" ]]; then
      echo -e "${C_GRAY}$(_line '─' 35)${C_RESET}"
      # insertions(+)の数字とテキストを緑に、deletions(-)の数字とテキストを赤に
      total_stats=$(echo "$total_stats" | sed -E 's/([0-9]+) insertion/\x1b[32m\1 insertion\x1b[0m/g')
      total_stats=$(echo "$total_stats" | sed -E 's/([0-9]+) deletion/\x1b[31m\1 deletion\x1b[0m/g')
      echo -e "  ${total_stats}"
    fi

    # タイムスタンプ
    echo ""
    echo -e "${C_GRAY}  🕐 $(date '+%H:%M:%S') │ ${interval}s refresh${C_RESET}"
    echo -e "${C_GRAY}  Press Ctrl+C to stop${C_RESET}"

    sleep "$interval"
  done
}

# -----------------------------------------------------------------------------
# branchdiff - ブランチ差分モニター（デフォルトブランチとの比較）
# -----------------------------------------------------------------------------
branchdiff() {
  local interval="${1:-2}"
  local prev_output=""

  while true; do
    # 現在の状態を取得
    local current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    local default_branch=$(_default_branch)

    # デフォルトブランチと同じ場合の処理
    if [[ "$current_branch" == "$default_branch" ]]; then
      local current_output="default_branch"

      # 前回と同じならスキップ
      if [[ "$current_output" == "$prev_output" ]]; then
        sleep "$interval"
        continue
      fi

      prev_output="$current_output"

      # カーソルをホームに移動して画面クリア
      printf '\033[H\033[J'

      # ヘッダー
      echo -e "${C_BLUE}${C_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
      echo -e "${C_BLUE}${C_BOLD}  📊 BRANCH DIFF${C_RESET}"
      echo -e "${C_BLUE}${C_BOLD}  ${current_branch} ← ${default_branch}${C_RESET}"
      echo -e "${C_BLUE}${C_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
      echo ""
      echo -e "  ${C_GRAY}Currently on default branch${C_RESET}"
      echo -e "  ${C_GRAY}No branch comparison available${C_RESET}"
      echo ""
      echo -e "${C_GRAY}  🕐 $(date '+%H:%M:%S') │ ${interval}s refresh${C_RESET}"
      echo -e "${C_GRAY}  Press Ctrl+C to stop${C_RESET}"
      sleep "$interval"
      continue
    fi

    # ブランチ間の差分ファイル数を取得
    local changed_files=$(git diff --name-only "${default_branch}...HEAD" 2>/dev/null | wc -l | tr -d ' ')
    local commits_ahead=$(git rev-list --count "${default_branch}..HEAD" 2>/dev/null || echo "0")
    local untracked_count=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

    # 現在の出力内容を生成
    local current_output=""
    current_output+="${current_branch}|${default_branch}|${changed_files}|${commits_ahead}|${untracked_count}"

    # 差分リストを取得して状態に追加
    current_output+="|"
    current_output+=$(git diff --name-status "${default_branch}...HEAD" 2>/dev/null | sort)
    current_output+="|"
    current_output+=$(git ls-files --others --exclude-standard 2>/dev/null | sort)

    # 前回と同じなら再描画をスキップ
    if [[ "$current_output" == "$prev_output" ]]; then
      sleep "$interval"
      continue
    fi

    # 変更があった場合のみ再描画
    prev_output="$current_output"

    # カーソルをホームに移動して画面クリア
    printf '\033[H\033[J'

    # ヘッダー
    echo -e "${C_BLUE}${C_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
    echo -e "${C_BLUE}${C_BOLD}  📊 BRANCH DIFF${C_RESET}"
    echo -e "${C_BLUE}${C_BOLD}  ${current_branch} ← ${default_branch}${C_RESET}"
    echo -e "${C_BLUE}${C_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
    echo ""

    # サマリー
    echo -e "  ${C_BLUE}↑${C_RESET} Commits ahead: ${C_BOLD}${commits_ahead}${C_RESET}"
    echo -e "  ${C_YELLOW}≠${C_RESET} Changed files: ${C_BOLD}${changed_files}${C_RESET}"
    if [[ $untracked_count -gt 0 ]]; then
      echo -e "  ${C_GRAY}?${C_RESET} Untracked:     ${C_BOLD}${untracked_count}${C_RESET}"
    fi
    echo ""

    # ファイルツリー表示（tree風）
    echo -e "${C_GRAY}$(_line '─' 35)${C_RESET}"
    echo ""

    if [[ $changed_files -gt 0 ]] || [[ $untracked_count -gt 0 ]]; then
      # 変更があるファイルを収集
      local -A changed_files_map=()
      while IFS=$'\t' read -r file_status filepath; do
        # パスの正規化（先頭の./を削除）
        filepath="${filepath#./}"
        [[ -n "$filepath" ]] && changed_files_map[$filepath]="$file_status"
      done < <({
        git diff --name-status "${default_branch}...HEAD" 2>/dev/null
        git ls-files --others --exclude-standard 2>/dev/null | awk '{print "U\t" $0}'
      })

      # トップレベルの構造を取得（ディレクトリとファイル）
      local -a top_dirs=()
      local -a top_files=()

      # git ls-tree でトップレベルを取得
      while read -r line; do
        [[ -z "$line" ]] && continue
        type=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | awk '{print $4}')

        if [[ -n "$name" && "$type" == "tree" ]]; then
          top_dirs+=("$name")
        elif [[ -n "$name" && "$type" == "blob" ]]; then
          top_files+=("$name")
        fi
      done < <(git ls-tree HEAD 2>/dev/null)

      # 変更があるディレクトリを特定（untrackedディレクトリも追加）
      local -A dir_has_changes
      local -A seen_top_dirs
      local -A seen_top_files

      for dir in "${top_dirs[@]}"; do
        seen_top_dirs[$dir]=1
      done

      for file in "${top_files[@]}"; do
        seen_top_files[$file]=1
      done

      for filepath in "${(@k)changed_files_map}"; do
        if [[ "$filepath" == */* ]]; then
          # ディレクトリ内のファイル
          topdir=$(echo "$filepath" | cut -d'/' -f1)
          dir_has_changes[$topdir]=1
          # untrackedディレクトリがtop_dirsにない場合は追加
          if [[ -z "${seen_top_dirs[$topdir]}" ]]; then
            top_dirs+=("$topdir")
            seen_top_dirs[$topdir]=1
          fi
        else
          # ルートレベルのファイル（untrackedファイル含む）
          if [[ -z "${seen_top_files[$filepath]}" ]]; then
            top_files+=("$filepath")
            seen_top_files[$filepath]=1
          fi
        fi
      done

      echo "  ."

      # ディレクトリを表示（total_itemsはtop_files更新後に計算）
      local total_items=$((${#top_dirs[@]} + ${#top_files[@]}))
      local current=0

      for dir in "${top_dirs[@]}"; do
        current=$((current + 1))
        local is_last=0
        [[ $current -eq $total_items ]] && is_last=1

        if [[ -n "${dir_has_changes[$dir]}" ]]; then
          # 変更があるディレクトリは展開
          if [[ $is_last -eq 1 ]] && [[ ${#top_files[@]} -eq 0 ]]; then
            echo "  └─ ${dir}/"
            prefix="     "
          else
            echo "  ├─ ${dir}/"
            prefix="  │  "
          fi

          # ディレクトリ内の変更ファイルを表示
          local -a dir_changed_files=()
          for filepath in "${(@k)changed_files_map}"; do
            if [[ "$filepath" == "${dir}/"* ]]; then
              dir_changed_files+=("$filepath")
            fi
          done

          local file_count=${#dir_changed_files[@]}
          local file_idx=0
          for filepath in "${(@on)dir_changed_files[@]}"; do
            file_idx=$((file_idx + 1))
            local file_is_last=0
            [[ $file_idx -eq $file_count ]] && file_is_last=1

            filename=$(basename "$filepath")
            file_status="${changed_files_map[$filepath]}"

            # Status icon and color
            case "$file_status" in
              M)
                icon="${C_YELLOW}●${C_RESET}"
                color="${C_YELLOW}"
                status_label="[mod]"
                ;;
              A)
                icon="${C_GREEN}+${C_RESET}"
                color="${C_GREEN}"
                status_label="[add]"
                ;;
              D)
                icon="${C_RED}−${C_RESET}"
                color="${C_RED}"
                status_label="[del]"
                ;;
              R*)
                icon="${C_BLUE}→${C_RESET}"
                color="${C_BLUE}"
                status_label="[ren]"
                ;;
              U)
                icon="${C_GRAY}?${C_RESET}"
                color="${C_GRAY}"
                status_label="[new]"
                ;;
              *)
                icon="${C_GRAY}?${C_RESET}"
                color="${C_GRAY}"
                status_label="[${file_status}]"
                ;;
            esac

            # Get stats
            if [[ "$file_status" == "U" ]]; then
              stats=$(wc -l < "$filepath" 2>/dev/null | awk '{print "+"$1}')
            else
              stats=$(git diff --numstat "${default_branch}...HEAD" -- "$filepath" 2>/dev/null | awk '{print "+"$1" -"$2}')
            fi
            stats=$(_colorize_stats "$stats")

            if [[ $file_is_last -eq 1 ]]; then
              echo -e "${prefix}└─ ${filename} ${icon} ${color}${status_label}${C_RESET} ${stats}"
            else
              echo -e "${prefix}├─ ${filename} ${icon} ${color}${status_label}${C_RESET} ${stats}"
            fi
          done
        else
          # 変更がないディレクトリは名前だけ
          if [[ $is_last -eq 1 ]] && [[ ${#top_files[@]} -eq 0 ]]; then
            echo "  └─ ${dir}/"
          else
            echo "  ├─ ${dir}/"
          fi
        fi
      done

      # トップレベルのファイルを表示
      for file in "${top_files[@]}"; do
        current=$((current + 1))
        local is_last=0
        [[ $current -eq $total_items ]] && is_last=1

        if [[ -n "${changed_files_map[$file]}" ]]; then
          # 変更があるファイルは詳細表示
          file_status="${changed_files_map[$file]}"

          # Status icon and color
          case "$file_status" in
            M)
              icon="${C_YELLOW}●${C_RESET}"
              color="${C_YELLOW}"
              status_label="[mod]"
              ;;
            A)
              icon="${C_GREEN}+${C_RESET}"
              color="${C_GREEN}"
              status_label="[add]"
              ;;
            D)
              icon="${C_RED}−${C_RESET}"
              color="${C_RED}"
              status_label="[del]"
              ;;
            R*)
              icon="${C_BLUE}→${C_RESET}"
              color="${C_BLUE}"
              status_label="[ren]"
              ;;
            U)
              icon="${C_GRAY}?${C_RESET}"
              color="${C_GRAY}"
              status_label="[new]"
              ;;
            *)
              icon="${C_GRAY}?${C_RESET}"
              color="${C_GRAY}"
              status_label="[${file_status}]"
              ;;
          esac

          # Get stats
          if [[ "$file_status" == "U" ]]; then
            stats=$(wc -l < "$file" 2>/dev/null | awk '{print "+"$1}')
          else
            stats=$(git diff --numstat "${default_branch}...HEAD" -- "$file" 2>/dev/null | awk '{print "+"$1" -"$2}')
          fi
          stats=$(_colorize_stats "$stats")

          if [[ $is_last -eq 1 ]]; then
            echo -e "  └─ ${file} ${icon} ${color}${status_label}${C_RESET} ${stats}"
          else
            echo -e "  ├─ ${file} ${icon} ${color}${status_label}${C_RESET} ${stats}"
          fi
        else
          # 変更がないファイルは名前だけ
          if [[ $is_last -eq 1 ]]; then
            echo "  └─ ${file}"
          else
            echo "  ├─ ${file}"
          fi
        fi
      done

      echo ""
    else
      # 差分がない場合でもroot構造を表示
      local -a top_dirs=()
      local -a top_files=()

      while read -r line; do
        type=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | awk '{print $4}')
        if [[ "$type" == "tree" ]]; then
          top_dirs+=("$name")
        elif [[ "$type" == "blob" ]]; then
          top_files+=("$name")
        fi
      done < <(git ls-tree HEAD 2>/dev/null)

      echo "  ."
      local total_items=$((${#top_dirs[@]} + ${#top_files[@]}))
      local current=0

      for dir in "${top_dirs[@]}"; do
        current=$((current + 1))
        if [[ $current -eq $total_items ]]; then
          echo "  └─ ${dir}/"
        else
          echo "  ├─ ${dir}/"
        fi
      done

      for file in "${top_files[@]}"; do
        current=$((current + 1))
        if [[ $current -eq $total_items ]]; then
          echo "  └─ ${file}"
        else
          echo "  ├─ ${file}"
        fi
      done

      echo ""
      echo -e "  ${C_GRAY}No changes from ${default_branch}${C_RESET}"
      echo ""
    fi

    # 合計差分（色付き）
    local total_stats=$(git diff --stat "${default_branch}...HEAD" 2>/dev/null | tail -1)
    if [[ -n "$total_stats" ]]; then
      echo -e "${C_GRAY}$(_line '─' 35)${C_RESET}"
      # insertions(+)の数字とテキストを緑に、deletions(-)の数字とテキストを赤に
      total_stats=$(echo "$total_stats" | sed -E 's/([0-9]+) insertion/\x1b[32m\1 insertion\x1b[0m/g')
      total_stats=$(echo "$total_stats" | sed -E 's/([0-9]+) deletion/\x1b[31m\1 deletion\x1b[0m/g')
      echo -e "  ${total_stats}"
    fi

    # タイムスタンプ
    echo ""
    echo -e "${C_GRAY}  🕐 $(date '+%H:%M:%S') │ ${interval}s refresh${C_RESET}"
    echo -e "${C_GRAY}  Press Ctrl+C to stop${C_RESET}"

    sleep "$interval"
  done
}

# -----------------------------------------------------------------------------
# pstatus - 全Worktree状態確認
# -----------------------------------------------------------------------------
pstatus() {
  _header "Parallel Tasks Overview"
  echo ""

  local git_root=$(_git_root)
  if [[ -z "$git_root" ]]; then
    _error "Not in a git repository"
    return 1
  fi

  # テーブルヘッダー
  printf "  ${C_BOLD}%-20s %-25s %-10s %s${C_RESET}\n" "TASK" "BRANCH" "STATUS" "CHANGES"
  echo -e "  ${C_GRAY}$(_line '─' 65)${C_RESET}"

  # 各Worktreeの情報
  git worktree list --porcelain | grep '^worktree' | cut -d' ' -f2- | while read wt_path; do
    local branch=$(git -C "$wt_path" branch --show-current 2>/dev/null)
    local task=$(_branch_to_task "$branch")

    # ステータス判定
    local modified=$(git -C "$wt_path" diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    local staged=$(git -C "$wt_path" diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')

    local status_icon status_text
    if [[ $staged -gt 0 ]]; then
      status_icon="${C_GREEN}◆${C_RESET}"
      status_text="staged"
    elif [[ $modified -gt 0 ]]; then
      status_icon="${C_YELLOW}●${C_RESET}"
      status_text="dirty"
    else
      status_icon="${C_GREEN}✓${C_RESET}"
      status_text="clean"
    fi

    # 差分行数
    local additions=$(git -C "$wt_path" diff --numstat 2>/dev/null | awk '{s+=$1} END {print s+0}')
    local deletions=$(git -C "$wt_path" diff --numstat 2>/dev/null | awk '{s+=$2} END {print s+0}')
    local changes="${C_GREEN}+${additions}${C_RESET} ${C_RED}-${deletions}${C_RESET}"

    printf "  ${status_icon} %-18s %-25s %-10s %b\n" "$task" "$branch" "$status_text" "$changes"
  done

  echo ""
}

# -----------------------------------------------------------------------------
# pmerge - タスクをmainにマージ
# -----------------------------------------------------------------------------
pmerge() {
  local task_name="$1"
  local target_branch="${2:-main}"

  if [[ -z "$task_name" ]]; then
    _error "Usage: pmerge <task-name> [target-branch]"
    return 1
  fi

  local branch_name=$(_task_to_branch "$task_name")

  _header "Merging ${task_name}"

  _info "Branch: ${C_GREEN}${branch_name}${C_RESET} → ${C_BLUE}${target_branch}${C_RESET}"
  echo ""

  # メインのworktreeに移動
  local git_root=$(_git_root)
  cd "$git_root"

  # target branchに切り替え
  git checkout "$target_branch"
  git pull origin "$target_branch"

  # マージ
  if git merge "$branch_name" --no-ff -m "Merge ${branch_name} into ${target_branch}"; then
    _success "Merged successfully"
    _info "Run 'git push origin ${target_branch}' to push"
  else
    _error "Merge failed - resolve conflicts"
    return 1
  fi
}

# -----------------------------------------------------------------------------
# pclean - 完了タスクのWorktree削除
# -----------------------------------------------------------------------------
pclean() {
  local task_name="$1"

  _header "Cleanup Worktrees"

  if [[ -n "$task_name" ]]; then
    # 指定タスクを削除
    local branch_name=$(_task_to_branch "$task_name")
    local worktree_base=$(_worktree_base)
    local worktree_path="${worktree_base}/${task_name}"

    _info "Removing: ${task_name}"

    git worktree remove "$worktree_path" --force 2>/dev/null
    git branch -d "$branch_name" 2>/dev/null

    _success "Removed ${task_name}"
  else
    # fzfで選択
    local selected=$(git worktree list | grep -v "bare\|$(git rev-parse --show-toplevel)$" | fzf --multi --height 50% --header "Select worktrees to remove (TAB to multi-select)")

    if [[ -z "$selected" ]]; then
      _info "No worktree selected"
      return 0
    fi

    echo "$selected" | while read line; do
      local wt_path=$(echo "$line" | awk '{print $1}')
      local branch=$(echo "$line" | awk '{print $3}' | tr -d '[]')

      _info "Removing: ${wt_path}"
      git worktree remove "$wt_path" --force 2>/dev/null
      git branch -d "$branch" 2>/dev/null
    done

    _success "Cleanup complete"
  fi
}

# -----------------------------------------------------------------------------
# pdhelp - ヘルプ表示
# -----------------------------------------------------------------------------
pdhelp() {
  cat <<'EOF'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📚 Parallel Development Commands
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  【タスク作成】
    pdev <task-name> [base]   新規Worktree作成 + 4ペインタブ

    例: pdev feat-auth-login
        → Directory: ../feat-auth-login (Worktree作成)
        → Branch:    feat/auth/login
        → 4-pane layout with dual monitors

    ※ Cmd+T: 現在のディレクトリで4ペインタブ作成（Worktree作成なし）

  【状態確認】
    pstatus                   全Worktreeの状態一覧
    diffwatch [interval]      ワーキング差分モニター (default: 2s)
    branchdiff [interval]     ブランチ差分モニター (default: 2s)

  【マージ・削除】
    pmerge <task> [target]    タスクをマージ
    pclean [task]             Worktree削除 (fzf選択)

  【Worktree操作】
    gwl                       Worktree一覧
    gw                        fzfで選択して移動

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📐 Pane Layout
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ┌─────────┬──────────────────────────────┐
  │ WORKING │                              │
  │(diffwatch) 🤖 AI PANE (80%)            │
  ├─────────┤  (Claude Code)               │
  │ BRANCH  │                              │
  │(branchdiff)─────────────────────────────┤
  │         │  🔧 HUMAN (20%)              │
  └─────────┴──────────────────────────────┘
      20%              80%

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🎨 Status Icons
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ✓  clean      変更なし
  ●  dirty      未ステージの変更あり
  ◆  staged     ステージ済み（コミット待ち）
  ✗  conflict   コンフリクト発生

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# -----------------------------------------------------------------------------
# wh - WezTermヘルプ
# -----------------------------------------------------------------------------
wh() {
  cat <<'EOF'
┌─────────────────────────────────────────────────────────────┐
│  WezTerm チートシート                                       │
├─────────────────────────────────────────────────────────────┤
│  【タブ操作】                                               │
│    Cmd+T             新規タブ                               │
│    Cmd+W             タブを閉じる                           │
│    Cmd+1-9           タブ番号で移動                         │
│    Cmd+Shift+[/]     前/次のタブ                            │
│    Cmd+Opt+Shift+←/→ タブの順番を入れ替え                   │
├─────────────────────────────────────────────────────────────┤
│  【ペイン操作】                                             │
│    Cmd+D             縦分割 (左右に分ける)                  │
│    Cmd+Shift+D       横分割 (上下に分ける)                  │
│    Cmd+Opt+矢印      ペイン移動                             │
│    Cmd+Opt+hjkl      ペイン移動 (Vim風)                     │
│    Cmd+Opt+1/2/3     ペイン番号で移動                       │
│    Cmd+Shift+W       ペインを閉じる                         │
│    Cmd+Z             ペインズーム (トグル)                  │
├─────────────────────────────────────────────────────────────┤
│  【ペインサイズ調整】 Cmd+Shift+矢印                        │
│    ←                 境界線を左に (左縮む/右広がる)         │
│    →                 境界線を右に (左広がる/右縮む)         │
│    ↑                 境界線を上に                           │
│    ↓                 境界線を下に                           │
├─────────────────────────────────────────────────────────────┤
│  【その他】                                                 │
│    Cmd+Shift+Space   Quick Select (パス/URL選択)            │
│    Cmd+K             画面クリア                             │
│    Cmd+F             検索                                   │
│    Cmd+Shift+C       コピーモード                           │
│    Cmd+Shift+R       設定リロード                           │
│    Cmd+クリック      リンクを開く                           │
│    右クリック        ペースト                               │
└─────────────────────────────────────────────────────────────┘
EOF
}

# =============================================================================
# GitHub Light風 色設定（見やすさ重視）
# =============================================================================
# autosuggestions の色（グレー）
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6e7781"

# syntax-highlighting の色（バランス良く）
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=#116329,bold'         # コマンド: 緑
ZSH_HIGHLIGHT_STYLES[alias]='fg=#116329,bold'           # エイリアス: 緑
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#8250df,bold'         # ビルトイン: 紫
ZSH_HIGHLIGHT_STYLES[function]='fg=#8250df'             # 関数: 紫
ZSH_HIGHLIGHT_STYLES[path]='fg=#0550ae,underline'       # パス: 青
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#cf222e'        # 不明: 赤
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#0a3069' # 文字列: 濃い青
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#0a3069' # 文字列: 濃い青
ZSH_HIGHLIGHT_STYLES[arg0]='fg=#24292f'                 # 引数: 黒

# LS_COLORS（見やすさ重視）
export LS_COLORS='di=1;34:ln=35:so=32:pi=33:ex=1;31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=34;42'

# -----------------------------------------------------------------------------
# Powerlevel10k prompt config
# -----------------------------------------------------------------------------
[[ -f ~/.config/zsh/.p10k.zsh ]] && source ~/.config/zsh/.p10k.zsh
