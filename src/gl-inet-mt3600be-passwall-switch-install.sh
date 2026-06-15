#!/bin/sh

# 定义发布版本
version_number='1.0'

# 定义颜色输出函数
red() { echo -e "\033[31m\033[01m$1\033[0m"; }
green() { echo -e "\033[32m\033[01m$1\033[0m"; }
yellow() { echo -e "\033[33m\033[01m$1\033[0m"; }
blue() { echo -e "\033[34m\033[01m$1\033[0m"; }
light_magenta() { echo -e "\033[95m\033[01m$1\033[0m"; }
light_yellow() { echo -e "\033[93m\033[01m$1\033[0m"; }
cyan() { echo -e "\033[38;2;0;255;255m$1\033[0m"; }

##获取软路由型号信息
get_router_name() {
	model_info=$(cat /tmp/sysinfo/model)
	echo "$model_info"
}

get_router_hostname() {
	hostname=$(uci get system.@system[0].hostname)
	echo "$hostname 路由器"
}

#检查是否已经安装passwall
check_passwall_installed() {
	if [ -e /etc/init.d/passwall -a -e /etc/config/passwall ]; then
		return 0
	else
		return 1
	fi
}

# 检查是否安装了 whiptail
check_whiptail_installed() {
	if [ -e /usr/bin/whiptail ]; then
		return 0
	else
		return 1
	fi
}

#定义一个通用的Dialog
show_whiptail_dialog() {
	#判断是否具备whiptail dialog组件
	if check_whiptail_installed; then
		echo "whiptail has installed"
	else
		echo "# add your custom package feeds here" >/etc/opkg/customfeeds.conf
		opkg update
		opkg install whiptail
	fi
	local title="$1"
	local message="$2"
	local function_definition="$3"
	whiptail --title "$title" --yesno "$message" 15 60 --yes-button "是" --no-button "否"
	if [ $? -eq 0 ]; then
		eval "$function_definition"
	else
		echo "退出"
		exit 0
	fi
}

# 执行重启操作
do_reboot() {
	reboot
}

#提示用户要重启
show_reboot_tips() {
	reboot_code='do_reboot'
	show_whiptail_dialog "重启提醒" "           $(get_router_hostname)\n           $1passwall快捷开关完成.\n           开关生效需要重启路由器,\n           您是否要重启路由器?" "$reboot_code"
}

install_switch() {
	gl_name=$(get_router_name)
	case "$gl_name" in
		*3600*)
			;;
		*)
			echo "*      当前的路由器型号: "$gl_name | sed 's/ like iStoreOS//'
			red "并非MT3600BE 安装后无效！"
			exit 1
			;;
	esac
	if ! check_passwall_installed; then
		red "请先安装passwall！"
		exit 1
	fi

	mkdir -p /tmp/mt3600be_passwall_switch
	cd /tmp/mt3600be_passwall_switch
	wget -O passwall-mt3600be-switch.tar.gz "https://github.com/jinzhijiang/gl-inet-mt3600be-passwall-switch/releases/download/$version_number/passwall-mt3600be-switch.tar.gz"
	tar zxf passwall-mt3600be-switch.tar.gz
	cp passwall.sh /etc/gl-switch.d
	chmod +x /etc/gl-switch.d/passwall.sh
	# 清理旧版本遗留的 ubus 监听器与 rc.local 启动项(新版直接在开关脚本里启停 passwall,无需常驻进程)
	if [ -e /etc/rc.local ]; then
		sed -i '/\/etc\/passwall\/switch\/passwall-listener.sh &/d' "/etc/rc.local"
	fi
	rm -f /etc/passwall/switch/passwall-listener.sh
	uci set switch-button.@main[0].func='passwall'
	uci commit
	show_reboot_tips '安装'
}

uninstall_switch() {
	uci set switch-button.@main[0].func='none'
	uci commit
	if [ -e /etc/rc.local ]; then
		file="/etc/rc.local"
		sed -i '/\/etc\/passwall\/switch\/passwall-listener.sh &/d' "$file"
	fi
	rm -f /etc/passwall/switch/passwall-listener.sh
	rm -f /etc/gl-switch.d/passwall.sh
	show_reboot_tips '卸载'
}



while true; do
	clear
	gl_name=$(get_router_name)
	echo "***********************************************************************"
	echo "*      一键安装passwall快捷开关 v1.0 by @jinzhijiang        "
	echo "**********************************************************************"
	echo "*      当前的路由器型号: "$gl_name | sed 's/ like iStoreOS//'
	echo
	echo "*******支持的机型列表***************************************************"
	green "*******GL-iNet MT-3600 (MT3600BE) "
	echo "**********************************************************************"
	echo
	echo " 1. 安装快捷开关"
	echo " 2. 卸载快捷开关"
	echo " Q. 退出本程序"
	echo
	read -p "请选择一个选项: " choice

	case $choice in
	1)
		install_switch
		;;
	2)
		uninstall_switch
		;;
	q | Q)
		echo "退出"
		exit 0
		;;
	*)
		echo "无效选项，请重新选择。"
		;;
	esac

	read -p "按 Enter 键继续..."
done
