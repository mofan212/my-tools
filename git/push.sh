#!/bin/bash
# Written by mofan
# 2023-09-22
#
# 暂存当前变更并切换到目标分支，push 后又切回原始分支，使用 cherry-pick 将目标分支的提交 pick 到原始分支

# 判断指定目录是否存在
function existDir() {
  cd "$1" &>/dev/null || return 1
}

# 判断当前目录是否被 git 管理
function existGitDir() {
  # 如果当前目录被 git 管理，git rev-parse --is-inside-work-tree 将返回 true
  # &>/dev/null 相当于将任何信息都重定向到 /dev/null，如果有错，直接吞了
  git rev-parse --is-inside-work-tree &>/dev/null
  # 被 git 管理，返回 0；反之返回 128
  return $?
}

# 返回指定目录或当前目录下的 git 分支信息
function current_branch() {
  local folder
  folder="$(pwd)"
  #    [ -n "$1" ] && folder="$1"
  git -C "$folder" rev-parse --abbrev-ref HEAD | grep -v HEAD ||
    git -C "$folder" describe --exact-match HEAD ||
    git -C "$folder" rev-parse HEAD
}

# 判断是否存在冲突
function checkConflict() {
  # 有内容，-n 不为 0，即有冲突
  if [ -n "$(git diff --check)" ]; then
    echo "存在冲突，请人工操作"
    read -r -n 1
    exit
  fi
}

# 推送代码
# 1 目标分支 2 commit message 3 原始分支
function push() {
  eval "$(git add .)"
  git stash save "$2"
  git checkout "$1"
  # 先 push，防止目标分支未与远程关联，默认配置的远程仓库别名为 origin
  git push --set-upstream origin "$1"
  git pull
  git stash apply 0
  checkConflict
  eval "$(git add .)"
  git commit -m "$2"
  git pull
  checkConflict
  git push
  local commit_id
  # 获取上次提交的 short commit id，如果不加 --short 则显示完整的 commit id
  commit_id=$(git rev-parse --short HEAD)
  git checkout "$3"
  git pull
  git cherry-pick "$commit_id"
  checkConflict
  git pull
  checkConflict
  git push
  git stash drop
}

# 替换为目标项目目录
PROJECT_PATH=""
if [ -z "$PROJECT_PATH" ]; then
  read -r -p "项目目录信息为空，请前往脚本配置，或者手动录入: " INPUT_PATH
  while ! existDir "$INPUT_PATH"; do
    read -r -p "项目目录不存在，请重新输入: " INPUT_PATH
  done
  while ! existGitDir; do
    echo -e "\e[1;31m当前目录未被 git 管理\e[0m"
    read -r -p "请重新输入项目目录: " INPUT_PATH
    while ! existDir "$INPUT_PATH"; do
      read -r -p "项目目录不存在，请重新输入: " INPUT_PATH
    done
  done
  echo -e "\n"
fi

# 替换为目标分支
TARGET_BRANCH=""
if [ -z "$TARGET_BRANCH" ]; then
  read -r -p "目标分支信息为空，请前往脚本配置，或者手动录入: " INPUT_BRANCH
  while ! git show-ref --quiet refs/heads/"$INPUT_BRANCH"; do
    read -r -p "本地不存在目标分支，请重新输入: " INPUT_BRANCH
  done
  TARGET_BRANCH=$INPUT_BRANCH
  echo -e "\n"
fi

COMMIT_MESSAGE=$1
# -z 字符串长度为 0 时返回 true
if [ -z "$COMMIT_MESSAGE" ]; then
  echo -e "\e[1;31mcommit message 不能为空\e[0m"
  read -r -p "请重新输入 commit message: " INPUT_COMMIT_MESSAGE
  while [ -z "$INPUT_COMMIT_MESSAGE" ]; do
    read -r -p "commit message 为空，请重新录入: " INPUT_COMMIT_MESSAGE
  done
  COMMIT_MESSAGE=$INPUT_COMMIT_MESSAGE
  echo -e "\n"
fi

if [ -n "$(git status -s)" ]; then
  CURRENT_BRANCH="$(current_branch)"
  # -eq 用于比较数字与变量，使用 = 比较字符串的相等
  if [ "$CURRENT_BRANCH" = "$TARGET_BRANCH" ]; then
    echo "\e[1;33m当前已位于目标分支，不执行任何操作\e[0m"
  else
    push "$TARGET_BRANCH" "$COMMIT_MESSAGE" "$CURRENT_BRANCH"
  fi
else
  echo -e "\e[1;33m当前仓库下不存在变更文件\e[0m"
fi

echo -e "\n按任意键退出..."
read -r -n 1