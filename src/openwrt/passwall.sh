#!/bin/sh

action=$1

# 记录开关到底有没有调到本脚本,以及传进来的参数是什么
logger -t passwall-switch "passwall.sh called with action=[$action]"

if [ "$action" = "on" ];then
	logger -t passwall-switch "send ubus event: on"
	ubus send passwall.switch '{"action":"on"}'
fi

if [ "$action" = "off" ];then
	logger -t passwall-switch "send ubus event: off"
	ubus send passwall.switch '{"action":"off"}'
fi

sleep 10
