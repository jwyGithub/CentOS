#!/bin/bash

# ANSI颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 检查是否已安装 nvm
if [ -d "$HOME/.nvm" ]; then
    echo "${GREEN}nvm is already installed.${NC}"
    # 设置 nvm 相关环境变量和加载 nvm.sh
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    # 打印当前安装的 nvm 版本信息
    nvm_version=$(nvm --version)
    echo "${GREEN}nvm version: $nvm_version${NC}"
    # 打印当前 nvm 安装的路径
    echo "${GREEN}nvm installation path: $NVM_DIR${NC}"
    exit 0
fi

# 安装 nvm
echo "${YELLOW}nvm is not installed. Installing nvm...${NC}"
curl -s -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# 设置 nvm 相关环境变量和加载 nvm.sh
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# 打印当前安装的 nvm 版本信息
nvm_version=$(nvm --version)
echo "${GREEN}nvm version: $nvm_version${NC}"

# 打印当前 nvm 安装的路径
echo "${GREEN}nvm installation path: $NVM_DIR${NC}"

# 使用 nvm 安装 Node.js 的 LTS 版本
nvm install --lts

# 打印 Node.js 版本
node_version=$(node --version)
echo "${GREEN}Node.js version: $node_version${NC}"

# 打印 npm 版本
npm_version=$(npm --version)
echo "${GREEN}npm version: $npm_version${NC}"
