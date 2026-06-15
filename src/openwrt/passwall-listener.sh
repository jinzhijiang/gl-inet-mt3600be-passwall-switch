#!/bin/sh

logger -t passwall-listener "listener started, begin ubus listen passwall.switch"

ubus listen passwall.switch | \
while read line ; do
	# 打印收到的原始事件,用于核对解析格式
	logger -t passwall-listener "raw line: $line"

	iface=$(echo "$line" | awk -F'"' '{print $6}')
	logger -t passwall-listener "parsed iface=[$iface]"

	if [ "$iface" = "on" ];then
		logger -t passwall-listener "begin action on"
		uci set passwall.@global[0].enabled='1'
		uci commit passwall
		/etc/init.d/passwall restart >/dev/null 2>&1 &
		logger -t passwall-listener "end action on"
	fi

	if [ "$iface" = "off" ];then
		logger -t passwall-listener "begin action off"
		uci set passwall.@global[0].enabled='0'
		uci commit passwall
		/etc/init.d/passwall stop >/dev/null 2>&1 &
		logger -t passwall-listener "end action off"
	fi
done
