#!/bin/sh

# gl-switch 拨动开关处理脚本,直接启停 passwall。
# 拨到 on 调用本脚本传入 on,拨到 off 传入 off。
# 不再依赖 ubus send/listen 的常驻监听进程,避免监听进程退出后开关失效。

action=$1

# 记录开关到底有没有调到本脚本,以及传进来的参数是什么
logger -t passwall-switch "passwall.sh called with action=[$action]"

case "$action" in
	on)
		logger -t passwall-switch "begin action on"
		uci set passwall.@global[0].enabled='1'
		uci commit passwall
		/etc/init.d/passwall restart >/dev/null 2>&1 &
		logger -t passwall-switch "end action on"
		;;
	off)
		logger -t passwall-switch "begin action off"
		uci set passwall.@global[0].enabled='0'
		uci commit passwall
		/etc/init.d/passwall stop >/dev/null 2>&1 &
		logger -t passwall-switch "end action off"
		;;
	*)
		logger -t passwall-switch "unknown action: [$action], ignored"
		;;
esac
