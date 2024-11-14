#!/bin/bash

# 默认不是Oracle Cloud环境
IS_ORACLE_CLOUD=0

# 处理命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --oc)
            IS_ORACLE_CLOUD=1
            shift # 移动到下一个参数
            ;;
        --help)
            echo "用法: $0 [选项]"
            echo "选项:"
            echo "  --oc    指定当前环境为Oracle Cloud"
            echo "  --help  显示此帮助信息"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            echo "使用 --help 查看帮助信息"
            exit 1
            ;;
    esac
done

# 日志输出颜色函数
function info() {
    echo -e "\033[34m[INFO] $1\033[0m"
}

function error() {
    echo -e "\033[31m[ERROR] $1\033[0m"
}

function warning() {
    echo -e "\033[33m[WARNING] $1\033[0m"
}

function success() {
    echo -e "\033[32m[SUCCESS] $1\033[0m"
}

# 检查并获取GRUB配置文件位置
function get_grub_config() {
    GRUB_CFG=""
    if [ -f /boot/grub2/grub.cfg ]; then
        GRUB_CFG="/boot/grub2/grub.cfg"
    elif [ -f /etc/grub2.cfg ]; then
        GRUB_CFG="/etc/grub2.cfg"
    elif [ -f /boot/grub/grub.cfg ]; then
        GRUB_CFG="/boot/grub/grub.cfg"
    fi

    if [ -n "$GRUB_CFG" ]; then
        echo "$GRUB_CFG"
        return 0
    else
        return 1
    fi
}

# 检查是否为Oracle Cloud环境
function is_oracle_cloud() {
    if [ $IS_ORACLE_CLOUD -eq 1 ]; then
        return 0
    fi
    
    # 尝试通过dmidecode检测
    if dmidecode -s system-manufacturer 2>/dev/null | grep -q "Oracle"; then
        return 0
    fi
    
    return 1
}

# 判断当前系统是centos 7 还是 centos 8
function check_system() {
    if [ -f /etc/redhat-release ]; then
        version=`cat /etc/redhat-release | sed -r 's/.* ([0-9]+)\..*/\1/'`
        if [ $version == 7 ]; then
            return 7
        elif [ $version == 8 ]; then
            return 8
        else
            error "不支持的系统版本"
            exit 1
        fi
    else
        error "不支持的操作系统"
        exit 1
    fi
}

# Oracle Cloud特定的GRUB配置更新
function update_oracle_grub() {
    info "正在更新Oracle Cloud的GRUB配置..."
    
    # 备份原始GRUB配置
    cp /etc/default/grub /etc/default/grub.bak
    if [ $? -ne 0 ]; then
        error "备份GRUB配置失败"
        exit 1
    fi
    
    # 修改GRUB配置
    sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' /etc/default/grub
    sed -i 's/GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="crashkernel=auto console=tty0 console=ttyS0,9600 net.ifnames=0 biosdevname=0 numa=off"/' /etc/default/grub
    
    # 重新生成GRUB配置
    if [ -f /boot/efi/EFI/centos/grub.cfg ]; then
        grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
    else
        grub2-mkconfig -o /boot/grub2/grub.cfg
    fi
    
    if [ $? -eq 0 ]; then
        success "Oracle Cloud GRUB配置更新成功"
    else
        error "Oracle Cloud GRUB配置更新失败"
        # 还原备份
        mv /etc/default/grub.bak /etc/default/grub
        exit 1
    fi
}

# 升级内核
function update_kernel() {
    info "开始升级内核..."
    check_system
    system_version=$?
    
    # 检查是否为Oracle Cloud环境
    if is_oracle_cloud; then
        warning "检测到Oracle Cloud环境，将进行特殊处理..."
    fi
    
    if [ $system_version -eq 7 ]; then
        # CentOS 7 升级内核
        info "检测到CentOS 7系统，开始升级内核..."
        rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
        if [ $? -ne 0 ]; then
            error "导入ELRepo GPG密钥失败"
            exit 1
        fi
        
        rpm -Uvh http://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
        if [ $? -ne 0 ]; then
            error "安装ELRepo仓库失败"
            exit 1
        fi
        
        yum --enablerepo=elrepo-kernel install kernel-ml -y
        if [ $? -ne 0 ]; then
            error "安装新内核失败"
            exit 1
        fi
        
        grub2-set-default 0
        
        # Oracle Cloud特殊处理
        if is_oracle_cloud; then
            update_oracle_grub
        fi
        
        success "CentOS 7 内核升级完成"
    else
        # CentOS 8 升级内核
        info "检测到CentOS 8系统，开始升级内核..."
        rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
        if [ $? -ne 0 ]; then
            error "导入ELRepo GPG密钥失败"
            exit 1
        fi
        
        rpm -Uvh http://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
        if [ $? -ne 0 ]; then
            error "安装ELRepo仓库失败"
            exit 1
        fi
        
        dnf --disablerepo="*" --enablerepo="elrepo-kernel" list available
        dnf --enablerepo=elrepo-kernel install kernel-ml kernel-ml-devel kernel-ml-headers -y
        if [ $? -ne 0 ]; then
            error "安装新内核失败"
            exit 1
        fi
        
        grubby --default-kernel
        
        # Oracle Cloud特殊处理
        if is_oracle_cloud; then
            update_oracle_grub
        fi
        
        success "CentOS 8 内核升级完成"
    fi
    
    warning "请重启系统以应用新内核"
}

# 开启BBR
function enable_bbr() {
    info "检查内核版本..."
    if [ `uname -r | awk -F. '{print $1}'` -gt 4 ] || ([ `uname -r | awk -F. '{print $1}'` -eq 4 ] && [ `uname -r | awk -F. '{print $2}'` -ge 9 ]); then
        info "当前内核版本满足BBR要求，开始启用BBR..."
        if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
            echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        fi
        if ! grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
            echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        fi
        sysctl -p
        success "BBR启用成功"
        
        # 验证BBR是否开启
        if lsmod | grep -q bbr; then
            success "BBR已成功启用"
            echo "当前拥塞控制算法: $(sysctl -n net.ipv4.tcp_congestion_control)"
            echo "当前队列算法: $(sysctl -n net.core.default_qdisc)"
        else
            warning "BBR可能未正确启用，请检查系统配置"
        fi
    else
        warning "当前内核版本过低，需要先升级内核"
        update_kernel
    fi
}

# 查看系统中所有内核的详细信息
function show_all_kernel_info() {
    info "系统内核详细信息："
    echo "----------------------------------------"
    echo "1. 当前使用的内核版本："
    uname -r
    echo "----------------------------------------"
    echo "2. 系统默认启动内核："
    grubby --default-kernel 2>/dev/null || echo "无法获取默认内核信息"
    echo "----------------------------------------"
    echo "3. 已安装的所有内核RPM包："
    rpm -qa | grep kernel | sort
    echo "----------------------------------------"
    echo "4. GRUB中的所有内核条目："
    GRUB_CFG=$(get_grub_config)
    if [ $? -eq 0 ]; then
        echo "从 $GRUB_CFG 读取引导菜单："
        awk -F\' '$1=="menuentry " {print i++ " : " $2}' "$GRUB_CFG"
    else
        warning "未找到 GRUB 配置文件"
        echo "系统中的内核文件："
        ls -l /boot/vmlinuz-*
    fi

    echo "----------------------------------------"
    echo "5. 内核加载模块信息："
    lsmod | head -n 5
    echo "... (使用 lsmod 查看完整模块列表)"
    echo "----------------------------------------"
    echo "6. 内核编译信息："
    uname -a
    echo "----------------------------------------"
    echo "7. 内核参数信息："
    sysctl -a | grep kernel | head -n 5
    echo "... (使用 sysctl -a 查看完整内核参数)"
    echo "----------------------------------------"
    if [ -f /proc/version ]; then
        echo "8. 内核版本详细信息："
        cat /proc/version
        echo "----------------------------------------"
    fi
}

# 查看当前使用的内核版本
function show_current_kernel() {
    info "当前内核信息："
    echo "----------------------------------------"
    echo "当前内核版本: $(uname -r)"
    echo "内核发行版本: $(uname -v)"
    echo "系统架构: $(uname -m)"
    echo "操作系统: $(uname -o)"
    
    # 检查BBR状态
    echo "----------------------------------------"
    echo "BBR状态检查："
    if lsmod | grep -q bbr; then
        echo "BBR模块已加载"
        echo "当前拥塞控制算法: $(sysctl -n net.ipv4.tcp_congestion_control)"
        echo "当前队列算法: $(sysctl -n net.core.default_qdisc)"
    else
        echo "BBR模块未加载"
    fi
}

# 查看所有已安装的内核版本
function list_all_kernels() {
    info "系统中所有已安装的内核信息："
    echo "----------------------------------------"
    echo "已安装的内核RPM包："
    rpm -qa | grep kernel | sort
    
    echo "----------------------------------------"
    echo "GRUB引导菜单中的内核列表："
    
    GRUB_CFG=$(get_grub_config)
    if [ $? -eq 0 ]; then
        echo "从 $GRUB_CFG 读取引导菜单："
        awk -F\' '$1=="menuentry " {print i++ " : " $2}' "$GRUB_CFG"
    else
        warning "未找到 GRUB 配置文件"
        echo "系统中的内核文件："
        ls -l /boot/vmlinuz-*
    fi
    
    echo "----------------------------------------"
    echo "当前正在使用的内核版本："
    uname -r
}

# 查看系统默认启动内核
function show_default_kernel() {
    info "系统默认启动内核信息："
    echo "----------------------------------------"
    echo "默认启动内核: $(grubby --default-kernel)"
    echo "GRUB默认启动项: $(grubby --default-index)"
    
    # 显示GRUB配置信息
    if [ -f /etc/default/grub ]; then
        echo "----------------------------------------"
        echo "GRUB配置信息："
        cat /etc/default/grub | grep -v ^#
    fi
}

# 删除旧内核
function remove_old_kernels() {
    current_kernel=$(uname -r)
    info "当前使用的内核版本是: $current_kernel"
    echo "----------------------------------------"
    echo "已安装的内核列表："
    rpm -qa | grep kernel
    echo "----------------------------------------"
    warning "即将删除除当前内核外的所有旧内核，是否继续？[y/n]"
    read confirm
    if [ "$confirm" = "y" ]; then
        info "开始删除旧内核..."
        check_system
        system_version=$?
        
        if [ $system_version -eq 7 ]; then
            # CentOS 7
            yum install yum-utils -y
            package-cleanup --oldkernels --count=1
        else
            # CentOS 8
            dnf remove $(dnf repoquery --installonly --latest-limit=-1 -q)
        fi
        success "旧内核删除完成"
        
        echo "----------------------------------------"
        info "当前剩余内核列表："
        rpm -qa | grep kernel
    else
        info "取消删除操作"
    fi
}

# 内核管理子菜单
function kernel_management_menu() {
    while true; do
        clear
        echo "======================================"
        echo "        内核管理子菜单                "
        echo "======================================"
        if [ $IS_ORACLE_CLOUD -eq 1 ]; then
            echo "【当前环境：Oracle Cloud (手动指定)】"
        elif is_oracle_cloud; then
            echo "【当前环境：Oracle Cloud (自动检测)】"
        fi
        echo "1. 查看当前使用的内核版本"
        echo "2. 查看所有已安装的内核版本"
        echo "3. 查看系统默认启动内核"
        echo "4. 查看系统内核详细信息"
        echo "5. 删除旧内核"
        echo "6. 返回主菜单"
        echo "======================================"
        read -p "请输入你的选择 [1-6]: " subchoice

        case $subchoice in
            1)
                show_current_kernel
                ;;
            2)
                list_all_kernels
                ;;
            3)
                show_default_kernel
                ;;
            4)
                show_all_kernel_info
                ;;
            5)
                remove_old_kernels
                ;;
            6)
                return
                ;;
            *)
                error "无效的选择"
                ;;
        esac
        echo
        read -p "按回车键继续..."
    done
}

# 显示主菜单
function show_menu() {
    clear
    echo "======================================"
    echo "        BBR 开启脚本菜单              "
    echo "======================================"
    if [ $IS_ORACLE_CLOUD -eq 1 ]; then
        echo "【当前环境：Oracle Cloud (手动指定)】"
    elif is_oracle_cloud; then
        echo "【当前环境：Oracle Cloud (自动检测)】"
    fi
    echo "1. 升级内核"
    echo "2. 开启BBR"
    echo "3. 内核管理"
    echo "4. 重启系统"
    echo "5. 退出脚本"
    echo "======================================"
    read -p "请输入你的选择 [1-5]: " choice

    case $choice in
        1)
            update_kernel
            ;;
        2)
            enable_bbr
            ;;
        3)
            kernel_management_menu
            ;;
        4)
            warning "系统将在3秒后重启..."
            sleep 3
            reboot
            ;;
        5)
            success "感谢使用，再见！"
            exit 0
            ;;
        *)
            error "无效的选择"
            ;;
    esac
}

# 检查是否为root用户
if [ $EUID -ne 0 ]; then
    error "请使用root用户运行此脚本"
    exit 1
fi

# 主循环
while true; do
    show_menu
    echo
    read -p "按回车键继续..."
done
