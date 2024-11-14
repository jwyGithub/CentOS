#!/bin/bash

# 颜色变量
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查docker是否安装
function check_docker() {
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}Docker已安装，版本：${NC}"
        docker --version
        return 0
    else
        echo -e "${RED}Docker未安装${NC}"
        return 1
    fi
}

# 检查docker-compose是否安装
function check_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        echo -e "${GREEN}Docker Compose已安装，版本：${NC}"
        docker-compose --version
        return 0
    else
        echo -e "${RED}Docker Compose未安装${NC}"
        return 1
    fi
}

# 安装3x-ui
function install_3xui() {
    local install_dir="$HOME/3x-ui"
    
    # 检查容器是否已存在
    if docker ps -a | grep -q "3x-ui"; then
        echo -e "${YELLOW}3x-ui容器已存在，跳过安装${NC}"
        return
    fi

    # 创建目录
    if [ ! -d "$install_dir" ]; then
        mkdir -p "$install_dir"
        echo -e "${GREEN}创建目录 $install_dir${NC}"
    fi

    # 下载docker-compose.yml
    echo -e "${YELLOW}下载3x-ui的docker-compose.yml...${NC}"
    curl -o "$install_dir/docker-compose.yml" https://raw.githubusercontent.com/jwyGithub/oh-my-dev/next/docker/3x-ui.yml

    # 检查下载是否成功
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}docker-compose.yml下载成功${NC}"
        # 启动容器
        cd "$install_dir"
        docker-compose up -d
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}3x-ui启动成功${NC}"
        else
            echo -e "${RED}3x-ui启动失败${NC}"
        fi
    else
        echo -e "${RED}docker-compose.yml下载失败${NC}"
    fi
}

# 安装nginx
function install_nginx() {
    local install_dir="$HOME/nginx"
    
    # 检查容器是否已存在
    if docker ps -a | grep -q "nginx"; then
        echo -e "${YELLOW}nginx容器已存在，跳过安装${NC}"
        return
    fi

    # 创建目录
    if [ ! -d "$install_dir" ]; then
        mkdir -p "$install_dir"
        echo -e "${GREEN}创建目录 $install_dir${NC}"
    fi

    # 下载docker-compose.yml
    echo -e "${YELLOW}下载nginx的docker-compose.yml...${NC}"
    curl -o "$install_dir/docker-compose.yml" https://raw.githubusercontent.com/jwyGithub/oh-my-dev/next/docker/nginx.yml

    # 检查下载是否成功
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}docker-compose.yml下载成功${NC}"
        # 启动容器
        cd "$install_dir"
        docker-compose up -d
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}nginx启动成功${NC}"
        else
            echo -e "${RED}nginx启动失败${NC}"
        fi
    else
        echo -e "${RED}docker-compose.yml下载失败${NC}"
    fi
}

# 主函数
function main() {
    # 检查docker和docker-compose
    if ! check_docker || ! check_docker_compose; then
        echo -e "${RED}请先安装Docker和Docker Compose${NC}"
        exit 1
    fi

    # 显示菜单
    while true; do
        echo -e "\n${YELLOW}Docker服务安装菜单：${NC}"
        echo "1. 安装3x-ui"
        echo "2. 安装nginx"
        echo "3. 退出"
        
        read -p "请选择操作 [1-3]: " choice
        
        case $choice in
            1)
                install_3xui
                ;;
            2)
                install_nginx
                ;;
            3)
                echo -e "${GREEN}感谢使用，再见！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                ;;
        esac
    done
}

# 运行主函数
main
