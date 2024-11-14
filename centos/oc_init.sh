#!/bin/bash

# 颜色变量
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}请使用root用户运行此脚本${NC}"
    exit
fi

# 初始化函数
function initialize() {
    echo -e "${YELLOW}开始初始化系统...${NC}"
    
    # 修改镜像源
    if ! grep -q "vault.centos.org" /etc/yum.repos.d/CentOS-*; then
        sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
        sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
        echo -e "${GREEN}镜像源已更新${NC}"
    else
        echo -e "${YELLOW}镜像源已经修改过，跳过${NC}"
    fi

    # 安装python3-librepo
    if ! rpm -q python3-librepo >/dev/null 2>&1; then
        dnf install -y python3-librepo
        echo -e "${GREEN}python3-librepo已安装${NC}"
    else
        echo -e "${YELLOW}python3-librepo已存在，跳过${NC}"
    fi
}

# 更新系统函数
function update_system() {
    echo -e "${YELLOW}开始更新系统...${NC}"
    dnf update -y
    dnf makecache
    echo -e "${GREEN}系统更新完成${NC}"
}

# 防火墙操作函数
function manage_firewall() {
    while true; do
        echo -e "\n${YELLOW}防火墙管理菜单：${NC}"
        echo "1. 开启防火墙"
        echo "2. 关闭防火墙"
        echo "3. 重启防火墙"
        echo "4. 返回主菜单"
        
        read -p "请选择操作 [1-4]: " choice
        
        case $choice in
            1)
                systemctl start firewalld
                systemctl enable firewalld
                echo -e "${GREEN}防火墙已开启${NC}"
                ;;
            2)
                systemctl stop firewalld
                systemctl disable firewalld
                echo -e "${GREEN}防火墙已关闭${NC}"
                ;;
            3)
                systemctl restart firewalld
                echo -e "${GREEN}防火墙已重启${NC}"
                ;;
            4)
                return
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                ;;
        esac
    done
}

# 端口操作函数
function manage_ports() {
    while true; do
        echo -e "\n${YELLOW}端口管理菜单：${NC}"
        echo "1. 添加端口"
        echo "2. 删除端口"
        echo "3. 查看端口"
        echo "4. 返回主菜单"
        
        read -p "请选择操作 [1-4]: " choice
        
        case $choice in
            1)
                read -p "请输入要添加的端口(可以是单个端口如22或端口范围如9000-9999): " port
                if firewall-cmd --list-ports | grep -q "$port"; then
                    echo -e "${YELLOW}端口 $port 已经开放，跳过${NC}"
                else
                    firewall-cmd --permanent --add-port=$port/tcp
                    firewall-cmd --reload
                    echo -e "${GREEN}端口 $port 已添加${NC}"
                fi
                ;;
            2)
                read -p "请输入要删除的端口(可以是单个端口如22或端口范围如9000-9999): " port
                if firewall-cmd --list-ports | grep -q "$port"; then
                    firewall-cmd --permanent --remove-port=$port/tcp
                    firewall-cmd --reload
                    echo -e "${GREEN}端口 $port 已删除${NC}"
                else
                    echo -e "${YELLOW}端口 $port 未开放，跳过${NC}"
                fi
                ;;
            3)
                echo -e "${GREEN}当前开放的端口：${NC}"
                firewall-cmd --list-ports
                ;;
            4)
                return
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                ;;
        esac
    done
}

# 安装Docker函数
function install_docker() {
    if command -v docker &> /dev/null; then
        echo -e "${YELLOW}Docker已安装，当前版本：${NC}"
        docker --version
    else
        echo -e "${YELLOW}开始安装Docker...${NC}"
        dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
        dnf install -y docker-ce docker-ce-cli containerd.io
        systemctl start docker
        systemctl enable docker
        echo -e "${GREEN}Docker安装完成，版本：${NC}"
        docker --version
    fi

    if command -v docker-compose &> /dev/null; then
        echo -e "${YELLOW}Docker Compose已安装，当前版本：${NC}"
        docker-compose --version
    else
        echo -e "${YELLOW}开始安装Docker Compose...${NC}"
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        echo -e "${GREEN}Docker Compose安装完成，版本：${NC}"
        docker-compose --version
    fi
}

# 主菜单
while true; do
    echo -e "\n${YELLOW}主菜单：${NC}"
    echo "1. 系统初始化"
    echo "2. 系统更新"
    echo "3. 防火墙管理"
    echo "4. 端口管理"
    echo "5. 安装Docker"
    echo "6. 退出"
    
    read -p "请选择操作 [1-6]: " choice
    
    case $choice in
        1)
            initialize
            ;;
        2)
            update_system
            ;;
        3)
            manage_firewall
            ;;
        4)
            manage_ports
            ;;
        5)
            install_docker
            ;;
        6)
            echo -e "${GREEN}感谢使用，再见！${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
    esac
done
