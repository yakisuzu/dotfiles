#!/bin/sh

# stale な worktree のメタデータを掃除
git worktree prune

# マージ済みブランチを削除する (main/master/現在のブランチは対象外)
# worktree に checkout されているブランチは worktree ごと削除してから消す
git branch --merged | while IFS= read -r line; do
  marker=$(printf '%s' "$line" | cut -c1)
  branch=$(printf '%s' "$line" | sed 's/^..//')

  case "$branch" in
    main|master|"") continue ;;
  esac

  # 現在のブランチ (*) は削除しない
  [ "$marker" = "*" ] && continue

  # worktree に checkout されている (+) 場合は worktree を先に削除
  if [ "$marker" = "+" ]; then
    wt=$(git worktree list --porcelain | awk -v b="refs/heads/$branch" '
      /^worktree /{p=substr($0,10)}
      $0=="branch "b{print p}')
    if [ -n "$wt" ]; then
      if git worktree remove "$wt"; then
        echo "removed worktree: $wt ($branch)"
      else
        echo "skip: worktree に変更あり: $wt ($branch)" >&2
        continue
      fi
    fi
  fi

  git branch -d "$branch"
done
