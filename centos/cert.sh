#!/bin/bash

# 颜色变量
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
function log_info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

function log_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

function log_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

function log_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

# 安装socat
function install_socat() {
    if ! command -v socat &> /dev/null; then
        log_info "正在安装socat..."
        if dnf install -y socat; then
            log_success "socat安装成功"
        else
            log_error "socat安装失败"
            exit 1
        fi
    else
        log_info "socat已安装，跳过"
    fi
}

# 安装acme.sh
function install_acme() {
    if ! command -v acme.sh &> /dev/null; then
        log_info "正在安装acme.sh..."
        if curl https://get.acme.sh | sh; then
            log_success "acme.sh安装成功"
        else
            log_error "acme.sh安装失败"
            exit 1
        fi
    else
        log_info "acme.sh已安装，跳过"
    fi

    # 切换证书生成方式为letsencrypt
    log_info "切换证书生成方式为letsencrypt..."
    ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    log_success "证书生成方式切换完成"
}

# 验证域名解析
function verify_domain() {
    local domain=$1
    local current_ip=$(curl -s ipv4.icanhazip.com)
    local domain_ip=$(dig +short ${domain})

    if [ -z "$domain_ip" ]; then
        log_error "无法解析域名 ${domain}"
        return 1
    fi

    if [ "$current_ip" != "$domain_ip" ]; then
        log_error "域名 ${domain} 解析的IP ($domain_ip) 与当前服务器IP ($current_ip) 不匹配"
        return 1
    fi

    return 0
}

# 检查证书是否存在
function check_cert_exists() {
    local domain=$1
    if [ -d "$HOME/.acme.sh/${domain}" ]; then
        log_warning "域名 ${domain} 的证书已存在"
        return 0
    fi
    return 1
}

# 生成证书
function cloudflare_ssl() {
    # 检查参数
    if [ $# -ne 4 ]; then
        log_error "使用方法: $0 <域名> <证书路径> <CF_Key> <CF_Email>"
        exit 1
    fi

    # 设置变量
    export CF_Domain=$1
    export cert_path=$2
    export CF_Key=$3
    export CF_Email=$4

    # 验证参数
    if [ -z "$CF_Domain" ] || [ -z "$cert_path" ] || [ -z "$CF_Key" ] || [ -z "$CF_Email" ]; then
        log_error "所有参数都不能为空"
        exit 1
    }

    # 检查证书路径
    if [ ! -d "$cert_path" ]; then
        log_info "创建证书目录 ${cert_path}"
        mkdir -p "$cert_path"
    fi

    # 验证域名解析
    log_info "验证域名解析..."
    if ! verify_domain "$CF_Domain"; then
        exit 1
    fi

    # 检查证书是否已存在
    if check_cert_exists "$CF_Domain"; then
        read -p "是否重新生成证书？(y/n) " answer
        if [[ "$answer" != "y" ]]; then
            log_info "取消证书生成"
            exit 0
        fi
    fi

    # 设置Cloudflare API
    export CF_Key
    export CF_Email

    log_info "开始生成证书..."

    # 生成证书
    if ~/.acme.sh/acme.sh --issue --dns dns_cf -d ${CF_Domain} -d *.${CF_Domain} --log; then
        log_success "证书生成成功"
    else
        log_error "证书生成失败"
        exit 1
    fi

    # 安装证书
    log_info "正在安装证书到指定目录..."
    if ~/.acme.sh/acme.sh --installcert -d ${CF_Domain} -d *.${CF_Domain} \
        --ca-file ${cert_path}/ca.cer \
        --cert-file ${cert_path}/cert.crt \
        --key-file ${cert_path}/private.key \
        --fullchain-file ${cert_path}/fullchain.cer; then
        
        log_success "证书安装完成"
        log_info "证书路径: ${cert_path}"
        log_info "CA证书: ${cert_path}/ca.cer"
        log_info "证书文件: ${cert_path}/cert.crt"
        log_info "私钥文件: ${cert_path}/private.key"
        log_info "完整链: ${cert_path}/fullchain.cer"
    else
        log_error "证书安装失败"
        exit 1
    fi
}

# 主函数
function main() {
    log_info "开始安装必要组件..."
    install_socat
    install_acme
    
    # 获取参数
    read -p "请输入域名: " domain
    read -p "请输入证书存放路径: " cert_path
    read -p "请输入Cloudflare API Key: " cf_key
    read -p "请输入Cloudflare Email: " cf_email

    # 生成证书
    cloudflare_ssl "$domain" "$cert_path" "$cf_key" "$cf_email"
}

# 运行主函数
main
