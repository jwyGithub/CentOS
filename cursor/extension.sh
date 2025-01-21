#!/bin/bash

# 定义颜色变量
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 检查是否启用详细信息输出
show_info=false
for arg in "$@"
do
    if [ "$arg" = "--info" ]; then
        show_info=true
        break
    fi
done

# 检查 code 命令是否存在
if ! command -v code &> /dev/null; then
    echo -e "${RED}错误: VSCode (code) 命令未找到!${NC}"
    echo -e "${BLUE}请确保 VSCode 已正确安装且已添加到系统环境变量中。${NC}"
    exit 1
fi

# 保存原始代理设置
original_http_proxy=$http_proxy
original_https_proxy=$https_proxy

# 设置代理（如果提供）
if [ ! -z "$proxy" ]; then
    echo -e "${BLUE}设置代理: ${GREEN}$proxy${NC}"
    export http_proxy=$proxy
    export https_proxy=$proxy
fi

echo -e "${BLUE}开始导出 VSCode 插件...${NC}"

# 获取所有VSCode插件列表
extensions=$(code --list-extensions)

if [ -z "$extensions" ]; then
    echo -e "${RED}未找到已安装的 VSCode 插件！${NC}"
    exit 1
fi

# 统计插件数量
extension_count=$(echo "$extensions" | wc -l)
echo -e "${BLUE}找到 ${GREEN}$extension_count${BLUE} 个已安装的插件${NC}"

# 处理排除列表
if [ ! -z "$exclude" ]; then
    echo -e "${YELLOW}检测到排除列表: ${exclude}${NC}"
    # 将排除列表转换为数组
    IFS=',' read -ra EXCLUDE_ARRAY <<< "$exclude"
fi

# 遍历每个插件并使用cursor安装
current=0
skipped=0
for extension in $extensions
do
    # 检查是否在排除列表中
    skip=false
    if [ ! -z "$exclude" ]; then
        for excluded in "${EXCLUDE_ARRAY[@]}"; do
            if [ "$extension" = "$excluded" ]; then
                ((skipped++))
                echo -e "${YELLOW}跳过排除的插件: ${extension}${NC}"
                skip=true
                break
            fi
        done
    fi
    
    if [ "$skip" = true ]; then
        continue
    fi

    ((current++))
    echo -e "${BLUE}[${current}/$((extension_count-skipped))] 正在安装插件: ${GREEN}$extension${NC}"
    
    # 执行安装命令并捕获输出
    output=$(cursor --install-extension "$extension" 2>&1)
    
    # 如果启用了详细信息输出，则显示安装信息
    if [ "$show_info" = true ]; then
        echo -e "${WHITE}$output${NC}"
    fi
done

# 恢复原始代理设置
if [ ! -z "$proxy" ]; then
    echo -e "${BLUE}恢复原始代理设置${NC}"
    if [ -z "$original_http_proxy" ]; then
        unset http_proxy
    else
        export http_proxy=$original_http_proxy
    fi
    
    if [ -z "$original_https_proxy" ]; then
        unset https_proxy
    else
        export https_proxy=$original_https_proxy
    fi
fi

echo -e "${GREEN}✨ 所有插件安装完成！${NC}"
if [ $skipped -gt 0 ]; then
    echo -e "${YELLOW}已跳过 ${skipped} 个排除的插件${NC}"
fi
