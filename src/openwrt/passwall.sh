#!/bin/sh

# gl-switch 拨动开关处理脚本,直接启停 passwall。
# 拨到 on 调用本脚本传入 on,拨到 off 传入 off。
# 不再依赖 ubus send/listen 的常驻监听进程,避免监听进程退出后开关失效。

action=$1

# 记录开关到底有没有调到本脚本,以及传进来的参数是什么
logger -t passwall-switch "passwall.sh called with action=[$action]"

# GL 用 `flock /var/lock/gl-switch.lock` 串行化所有 gl-switch.d 脚本,
# flock 打开锁文件占用 fd 3 并被本脚本及其子进程继承。
# passwall (re)start 会拉起常驻守护进程(xray/dnsmasq 等),若让它们继承 fd 3,
# 则只要 passwall 在运行,gl-switch.lock 就一直被占用,后续任何拨动都会卡死拿不到锁。
# 因此后台执行时用 setsid 脱离会话,并用 `3>&-` 关闭继承来的锁 fd,
# 保证本脚本一退出锁立即释放。
run_detached() {
	setsid "$@" >/dev/null 2>&1 3>&- &
}

case "$action" in
	on)
		logger -t passwall-switch "begin action on"
		uci set passwall.@global[0].enabled='1'
		uci commit passwall
		run_detached /etc/init.d/passwall restart
		logger -t passwall-switch "end action on"
		;;
	off)
		logger -t passwall-switch "begin action off"
		uci set passwall.@global[0].enabled='0'
		uci commit passwall
		run_detached /etc/init.d/passwall stop
		logger -t passwall-switch "end action off"
		;;
	*)
		logger -t passwall-switch "unknown action: [$action], ignored"
		;;
esac
