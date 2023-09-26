#!/bin/bash
# Written by mofan
#
# 通过完整的项目地址或者项目名称依次在 GitHub、Gitee 上拉取代码
# 适用场景较为局限，拉取代码时需要两种信息：1. 项目所属用户名 2. 项目名
# 在知道项目名的情况下，一般并不知道项目所属用户名，常用于拉取某一特定用户名下的项目

GITHUB_USER_NAME=""
GITEE_USER_NAME=""

function delExistingProject() {
  if [ -d "$1" ]; then
    echo "项目已存在，将删除原文件..."
    rm -rf "$1"
  fi
}

while true; do
  echo " ==> 注意：若项目目录下存在与拉取项目名相同的目录，将会被无提示递归删除！ <=="
  read -r -p "请输入 projectName 或完整的克隆地址: " path
  if [[ $path == git* ]] || [[ $path == http* ]]; then
    # 根据完整的克隆地址获取项目名称
    tempFileName=${path##*/}
    tempFileName=${tempFileName%%.*}
    delExistingProject "$tempFileName"
    if git clone "$path"; then
      echo "成功使用地址克隆项目！"
      break
    else
      echo -e "克隆失败，请重新输入 projectName 或完整的克隆地址！\n"
    fi
  else
    projectName=$path
    delExistingProject "$projectName"
    echo "尝试在 GitHub 下使用 HTTP 克隆..."
    if [ -z "$GITHUB_USER_NAME" ]; then
      echo "拉取项目的 GitHub 所有者用户名为空"
      read -r -p "请输入: " GITHUB_USER_NAME
    fi
    if git clone https://github.com/"$GITHUB_USER_NAME"/my-tools.git"$projectName".git; then
      echo "成功在 GitHub 下使用 HTTP 克隆项目！"
      break
    else
      echo -e "在 GitHub 下使用 HTTP 克隆失败 :( \n"
      echo "尝试在 Gitee 下使用 SSH 克隆..."
      if [ -z "$GITEE_USER_NAME" ]; then
        echo "拉取项目的 Gitee 所有者用户名为空"
        read -r -p "请输入: " GITEE_USER_NAME
      fi
      if git clone https://gitee.com/"$GITEE_USER_NAME"/"$projectName".git; then
        echo "成功在 Gitee 下使用 SSH 克隆项目！"
        break
      else
        echo -e "克隆失败，请重新输入 projectName 或完整的克隆地址！\n"
      fi
    fi
  fi
done
